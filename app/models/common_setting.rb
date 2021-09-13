class CommonSetting < ApplicationRecord
  enum type: {"Tenant-Setting": 1, "User-Setting": 2, "Machine-Setting": 3}
  enum machine_type: {"Ethernet": 1, "Rs232": 2, "Ct/Pt": 3}

  def self.part(tenant, shift_no, date)

    tenant = Tenant.find(tenant)
    shifts = Shifttransaction.includes(:shift).where(shifts: {tenant_id: tenant})
    shift = shifts.find_by_shift_no(shift_no)
       
    case
    when shift.day == 1 && shift.end_day == 1
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time
    when shift.day == 1 && shift.end_day == 2
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
    else
      start_time = (date+" "+shift.shift_start_time).to_time+1.day
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
    end
        
    tenant.machines.where(controller_type: 1).order(:id).map do |mac|
    machine_log = mac.machine_daily_logs.where("created_at >=? AND created_at <?",start_time,end_time).order(:id)
    machine_log.each do |log|

      unless log.machine_status == 100
         if mac.parts.present?
           cur_prod_data = mac.parts.last
           if cur_prod_data.part == log.parts_count && cur_prod_data.program_number == log.programe_number
              unless cur_prod_data.cycle_start.present? || log.machine_status != 3
                cyc_tym = (log.run_time.to_i)*60 + (log.run_time_seconds.to_i/1000)
                cur_prod_data.update(cycle_start: log.created_at, cycle_st_to_st: cyc_tym)
              end
              puts "SAME PART RUNNING"
           else

            cutt = (log.total_cutting_time.to_i * 60) + (log.total_cutting_second.to_i / 1000)
            cutt_time = cutt - cur_prod_data.cutting_time.to_i
            cycle_time = (log.run_time.to_i * 60) + (log.run_second.to_i / 1000)
            cur_prod_data.update(is_active: true,cutting_time: cutt_time, cycle_time: cycle_time, part_end_time: log.created_at, shift_no: shift.shift_no,shifttransaction_id: shift.id,cycle_st_to_st:curr_part_st_time,cycle_start:curr_part_cy_start)
 
            if log.machine_status == 3
            st_time = Time.now
          end
          cutt = (log.total_cutting_time.to_i * 60) + (log.total_cutting_second.to_i / 1000)
          Part.create(date: log.created_at, shift_no: shift.shift_no, part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: cutt, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: log.created_at, part_end_time: log.created_at, cycle_start: st_time, status: 1, is_active: false, deleted_at: nil, shifttransaction_id: shift.id, machine_id: mac.id)
         end

         # end

        else
          if log.machine_status == 3
            st_time = Time.now
          end
          cutt = (log.total_cutting_time.to_i * 60) + (log.total_cutting_second.to_i / 1000)
          Part.create(date: log.created_at, shift_no: shift.shift_no, part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: cutt, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: log.created_at, part_end_time: log.created_at, cycle_start: st_time, status: 1, is_active: false, deleted_at: nil, shifttransaction_id: shift.id, machine_id: mac.id)
         end
      else
        puts "status 100"
      end
    end
    end
  end


  def self.report(tenant, shift_no, date)
    @alldata = []
    tenant = Tenant.find(tenant)
    shifts = Shifttransaction.includes(:shift).where(shifts: {tenant_id: tenant})
    shift = shifts.find_by_shift_no(shift_no)
    case
    when shift.day == 1 && shift.end_day == 1
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time
    when shift.day == 1 && shift.end_day == 2
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
    else
      start_time = (date+" "+shift.shift_start_time).to_time+1.day
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
    end
    machine_ids = Tenant.find(tenant).machines.where(controller_type: 1).pluck(:id,:machine_name)
    mac_id = machine_ids.map{|i| i[0]}
    full_logs = MachineDailyLog.where(machine_id: mac_id)
    full_parts = Part.where(date: date, shift_no:shift_no, machine_id: mac_id)
    macro_signals = MacroSignal.where("update_date >=? AND end_date <?",start_time.strftime("%Y-%m-%d %H:%M:%S"),end_time.strftime("%Y-%m-%d %H:%M:%S"))
    operator_allocations = OperatorAllocation.where(date: date.to_time.strftime("%Y-%m-%d %H:%M:%S"), shifttransaction_id: shift.id)
    operators = Operator.all.group_by{|i| i[:id]}
    operation_managements = OperationManagement.all.group_by{|i| i[:id]} 
   machine_ids.each do |mac|
      machine_log = full_logs.select{|a| a.machine_id == mac[0]}
      logs = machine_log.select{|a| a.created_at >= start_time && a.created_at < end_time-1 }
      part = full_parts.select{|b|b.machine_id == mac[0] && b.cycle_start != nil && b.part_end_time >= start_time && b.part_end_time < end_time-1}     
      times = Machine.new_run_time(logs, full_logs, start_time, end_time)
      duration = (end_time.to_i - start_time.to_i).to_i
      run = times[:run_time]
      idle = times[:idle_time]
      stop = times[:stop_time]
      utilization = (run*100)/duration
      
       cycle_st_to_st = []
       cutting_time = []
       cycle_stop_to_stop = []
       cycle_time = []
      
      part.each do |p|
       cycle_time << {program_number: p.program_number, cycle_time: p.cycle_time.to_i, parts_count: p.part.to_i} 
       cutting_time << p.cutting_time.to_i
       cycle_st_to_st << p.cycle_start.to_time
       cycle_stop_to_stop << p.part_end_time.to_time
      end
     
        
      axis_loadd = []
      tempp_val = []
      puls_coder = []

      if logs.present?
        feed_rate_max = logs.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
        spindle_speed_max = logs.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
        sp_temp_min = logs.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        sp_temp_max = logs.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
        spindle_load_min = logs.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        spindle_load_max = logs.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
      
	mac_setting_id =  MachineSetting.find_by(machine_id: mac_id).id     
        data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)

            logs.last.x_axis.first.each_with_index do |key, index|
              if data_val.include?(key[0].to_s)
                load_value =  logs.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+logs.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                temp_value =  logs.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+logs.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                puls_value =  logs.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+logs.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                
                if load_value == " - "
                  load_value = "0 - 0" 
                end

                if temp_value == " - "
                  temp_value = "0 - 0" 
                end

                if puls_value == " - "
                  puls_value = "0 - 0" 
                end
              
                axis_loadd << {key[0].to_s.split(":").first => load_value}
                tempp_val << {key[0].to_s.split(":").first => temp_value}
                puls_coder << {key[0].to_s.split(":").first => puls_value}
              else
                axis_loadd << {key[0].to_s.split(":").first => "0 - 0"}
                tempp_val <<  {key[0].to_s.split(":").first => "0 - 0"}
                puls_coder << {key[0].to_s.split(":").first => "0 - 0"}
              end
            end
      else
       feed_rate_max = 0
       spindle_speed_max = 0
       sp_temp_min = 0
       sp_temp_max = 0
       spindle_load_min = 0
       spindle_load_max = 0
      end

      allocation_deltal = operator_allocations.find_by_machine_id(mac[0]).present? ? operator_allocations.find_by_machine_id(mac[0]) : nil
      
#transaction_detail = []
    
      if allocation_deltal.present? && allocation_deltal.operator_allot_details.present?
    transaction_detail = []    
    allocation_deltal.operator_allot_details.each do |detail|
     trans_duration = detail.end_time.localtime - detail.start_time.localtime
    byebug
        detail_cycle_time = operation_managements[detail.operation_management_id].first.load_unload_time + operation_managements[detail.operation_management_id].first.std_cycle_time      
        op_name = operators[detail.operator_id].pluck(:operator_name)
        if op_name.present?
          operator_name = op_name.first
        else
          operator_name = nil
        end
        trans_target = (trans_duration.to_i/detail_cycle_time).to_i
        trans_part = full_parts.select{|b|b.machine_id == mac[0] && b.cycle_start != nil && b.part_end_time >= detail.start_time && b.part_end_time < detail.end_time}
    	rej_rew = ["Reject_id","Rework_id"]	  
#byebug
    	macro_signals123 = macro_signals.select{|b|b.machine_id == mac[0] && rej_rew.include?(b.signal) && b.update_date >= detail.start_time.localtime && b.end_date < detail.end_time.localtime}.pluck(:value).sum.to_i
	mack_rej = macro_signals.select{|b|b.machine_id == mac[0] && b.signal == "Reject_id" && b.update_date >= detail.start_time.localtime && b.end_date < detail.end_time.localtime}.pluck(:value).sum.to_i
	mack_rew = macro_signals.select{|b|b.machine_id == mac[0] && b.signal == "Rework_id" && b.update_date >= detail.start_time.localtime && b.end_date < detail.end_time.localtime}.pluck(:value).sum.to_i
	
       if trans_part.count == 0 #|| trans_part.count < macro_signals123
         trans_eff = 0
         trans_effency = 0
	 good_parts = 0
         quality_oee = 0
         quality = 0
       elsif trans_part.count < macro_signals123
         trans_eff = (trans_part.count.to_f/trans_target.to_f).round(2)
         trans_effency = trans_eff *  100
         good_parts = 0
         quality_oee = 0
         quality = 0
       else
   	 good_parts = trans_part.count - macro_signals123
         trans_eff = (trans_part.count.to_f/trans_target.to_f).round(2)
         trans_effency = trans_eff *  100
         quality_oee = (good_parts.to_f/trans_part.count.to_f).round(2)
         quality = quality_oee * 100      
       end

         transaction_detail << {trans_start_time: detail.start_time.localtime, trans_end_time: detail.end_time.localtime, trans_duration: trans_duration, trans_target: trans_target, actual: trans_part.count, trans_eff: trans_eff, trans_effency: trans_effency, good_parts: good_parts, trans_qul: quality_oee, trans_effency: quality, operator_name:operator_name, operator_id: detail.operator_id , mack_rej: mack_rej, mack_rew: mack_rew}
       end
      else
       transaction_detail = []
      end   
       
#availability
        byebug
        available_time = (duration - shift.break_time.to_i).to_f
        availability_oee = (run/available_time).round(2)
        availability = (100*(run/available_time)).round(2)
#performance

       
        if transaction_detail.present?
        total_efficiency = transaction_detail.pluck(:trans_eff)
      #  efficiency_total = transaction_detail.pluck(:trans_effency)
        
        performance_oee = total_efficiency.sum/total_efficiency.count
        performance = (performance_oee * 100).round(2)
#quality
	oee_quality = transaction_detail.pluck(:trans_qul)
#        quality = transaction_detail.pluck(:quality)
	quality_oee = oee_quality.sum/oee_quality.count
        qulaity1 = (quality_oee * 100)
        else
         performance_oee = 0
         performance = 0
         quality_oee = 0
         qulaity1 = 0
        end
#        quality = (100*(ok_parts.to_f/total_parts_produced.to_f)).round(2)
#OEE
   #     byebug
        oee = (100*(availability_oee * performance_oee * quality_oee)).round(2) 
        operator_id = transaction_detail.pluck(:operator_id)
	approved = transaction_detail.pluck(:actual).sum.to_i
	rejected = transaction_detail.pluck(:mack_rej).sum.to_i
	reworked = transaction_detail.pluck(:mack_rew).sum.to_i
	target = transaction_detail.pluck(:trans_target).sum.to_i
       @alldata << [
        date,			#data[0]
        start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"), #data[1]
        duration, 		#data[2]
        shift.shift.id,		#data[3]
        shift.shift_no,		#data[4]
        operator_id,#(operator)	#data[5]
        mac[0], #(machine_id)	#data[6]
        "test",			#data[7]
        cutting_time.count,	#data[8]
        run,			#data[9]
        idle,			#data[10]
        stop,			#data[11]
        0,			#data[12]
        logs.count,		#data[13]
        utilization,		#data[14]
        tenant.id,		#data[15]
        cycle_time,		#data[16]
        cycle_st_to_st,		#data[17]
        feed_rate_max.to_s,	#data[18]
        spindle_speed_max.to_s,	#data[19]
        part.count,		#data[20]
        target,			#data[21]
        0,			#data[22]
        approved,		#data[23]
        rejected,		#data[24]
        reworked,		#data[25]
        cycle_stop_to_stop,	#data[26]
        cutting_time,		#data[27]
        spindle_load_min.to_s+' - '+spindle_load_max.to_s,	#data[28]
        sp_temp_min.to_s+' - '+sp_temp_max.to_s,		#data[29]
        axis_loadd,		#data[30]
        tempp_val,		#data[31]
        puls_coder,		#data[32]
        availability,	#data[33]
        performance,	#data[34]
	qulaity1,  		#data[35]
	oee,			#data[36]
	transaction_detail.pluck(:operator_name) #data[37]
       ]

end

if @alldata.present?
      @alldata.each do |data|
      
        if CncReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          CncReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[37], cycle_start_to_start: data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: data[33], perfomance: data[34], quality: data[35], parts_data: data[16], oee: data[36])
        else
          CncReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[37], cycle_start_to_start:data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: data[33], perfomance: data[34], quality: data[35],parts_data: data[16], oee: data[36])
        end
      end
    end
    hour_report = CommonSetting.hour_report(date,tenant,shift,start_time,end_time,full_logs,full_parts,machine_ids)
end
def self.hour_report(date,tenant,shift,start_time,end_time,full_logs,full_parts,mac_list)
 @all_data = []
	case
      when shift.day == 1 && shift.end_day == 1
        start_time = (date+" "+shift.shift_start_time).to_time
        end_time = (date+" "+shift.shift_end_time).to_time
      when shift.day == 1 && shift.end_day == 2
        start_time = (date+" "+shift.shift_start_time).to_time
        end_time = (date+" "+shift.shift_end_time).to_time+1.day
      else
        start_time = (date+" "+shift.shift_start_time).to_time+1.day
        end_time = (date+" "+shift.shift_end_time).to_time+1.day
      end
     
    #  byebug

#   @operator_detail = OperatorAllocation.where( shifttransaction_id:shift.id,date: date.to_time.strftime("%Y-%m-%d %H:%M:%S"))

   


      (start_time.to_i..end_time.to_i).step(3600) do |hour|
       
       (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
          unless hour_start_time[0].to_time == hour_end_time.to_time  
          puts hour_start_time[0].to_time..(hour_end_time.to_time)
          
          mac_list.each do |mac|
           
	   logs = full_logs.select{|i| i.machine_id == mac[0] && i.created_at >= hour_start_time[0].to_time && i.created_at < hour_end_time.to_time-1}
           part = full_parts.select{|b|b.machine_id == mac[0] && b.cycle_start != nil && b.part_end_time >= hour_start_time[0].to_time && b.part_end_time < hour_end_time.to_time-1}
 
	   times = Machine.new_run_time(logs, full_logs, hour_start_time[0].to_time, hour_end_time.to_time)  
           duration = (hour_end_time.to_time).to_i - (hour_start_time[0].to_time).to_i
           run = times[:run_time]
           idle = times[:idle_time]
           stop = times[:stop_time]
           utilization = (run*100)/duration
       cycle_st_to_st = []
       cutting_time = []
       cycle_stop_to_stop = []
       cycle_time = []
      
      part.each do |p|
       cycle_time << {program_number: p.program_number, cycle_time: p.cycle_time.to_i, parts_count: p.part.to_i} 
       cutting_time << p.cutting_time.to_i
       cycle_st_to_st << p.cycle_start.to_time
       cycle_stop_to_stop << p.part_end_time.to_time
      end
	  

      axis_loadd = []
      tempp_val = []
      puls_coder = []

      if logs.present?
        feed_rate_max = logs.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
        spindle_speed_max = logs.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
        sp_temp_min = logs.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        sp_temp_max = logs.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
        spindle_load_min = logs.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        spindle_load_max = logs.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
      
	      mac_setting_id =  MachineSetting.find_by(machine_id: mac[0]).id     
        data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)
        logs.last.x_axis.first.each_with_index do |key, index|
          if data_val.include?(key[0].to_s)
            load_value =  logs.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+logs.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
            temp_value =  logs.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+logs.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
            puls_value =  logs.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+logs.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
            
            if load_value == " - "
              load_value = "0 - 0" 
            end

            if temp_value == " - "
              temp_value = "0 - 0" 
            end

            if puls_value == " - "
              puls_value = "0 - 0" 
            end
          
            axis_loadd << {key[0].to_s.split(":").first => load_value}
            tempp_val << {key[0].to_s.split(":").first => temp_value}
            puls_coder << {key[0].to_s.split(":").first => puls_value}
          else
            axis_loadd << {key[0].to_s.split(":").first => "0 - 0"}
            tempp_val <<  {key[0].to_s.split(":").first => "0 - 0"}
            puls_coder << {key[0].to_s.split(":").first => "0 - 0"}
          end
        end
      else
       feed_rate_max = 0
       spindle_speed_max = 0
       sp_temp_min = 0
       sp_temp_max = 0
       spindle_load_min = 0
       spindle_load_max = 0
      end

  
#   byebug
 #  total_target = []

 #  machine_find = @operator_detail.select(machine_id: mac[0])  

 # machine_find = @operator_detail.select{|b|b.machine_id == mac[0]}

  #if machine_find.present?
 #  machine_find.last.operator_allot_details.each do |single_operator|
  # byebug 
  #  operation_start_time = single_operator.start_time.to_time.localtime
   # operation_end_time = single_operator.end_time.to_time.localtime
   # operator_id = single_operator.operator_id

    # operation_management_id = single_operator.operation_management_id

     #total_cycle_time = single_operator.operation_management.std_cycle_time.to_i + single_operator.operation_management.load_unload_time.to_i
  #   target_value = (hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i)/total_cycle_time
     #total_target << {start_time: hour_start_time[0].to_time, end_time: hour_end_time.to_time, operator_id: operator_id, operation_management_id: operation_management_id, target_value: target_value}
   
 
  #end

# end

# byebug
# if shift.operator_allocations.where(machine_id: mac[0]).last.nil?
#      operator_id = nil
#        target = 0
#      else
#       if shift.operator_allocations.where(machine_id: mac[0]).present?
#        shift.operator_allocations.where(machine_id: mac[0]).each do |ro|
#         aa = ro.from_date
#         bb = ro.to_date
#         cc = date
#          if cc.to_date.between?(aa.to_date,bb.to_date)
#            dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
#            if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
#              operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id
#              target = dd.operator_mapping_allocations.where(:date=>date.to_date).last.target
#           else           
#		operator_id = nil
#
 #            target = 0
 #           end
 #        else
 #           operator_id = nil
 #           target = 0
 #         end
 #        end
 #       else
 #         operator_id = nil
 #         target = 0
 #       end
 #     end

	   target = []
                 operator_detail = OperatorAllocation.where(machine_id:mac[0], shifttransaction_id:shift.id,date:date.to_time.strftime("%Y-%m-%d %H:%M:%S"))

                if operator_detail.present?
                        operator_detail.last.operator_allot_details.each do |i|
                                operator_id = i.operator_id
#                               operator_id = operator_detail.last.operator_allot_details.operator_id
        #               target = 0
 #                       operator_detail.operator_allot_details.each do |i|
  #                         time = (i.start_time.to_i..i.end_time.to_i).step(3600).each do |hour|
            #    byebug
   #                          cycle_time = i.operation_management.std_cycle_time.to_i + i.operation_management.load_unload_time.to_i
    #                          t_hr = hour/cycle_time
     #                         target << (i.end_time.to_i - i.start_time.to_i)/cycle_time
      #                       target << t_hr
#                               target = 0
                           end
                   #     end
##
                else
                        operator_id = nil
                        target = []
#                       target = 0
                end
                     total_target = target.sum
	

       @all_data << [
 
               date,
               hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1],
               duration,
               shift.shift.id,
               shift.shift_no,
               operator_id,
               mac[0],
               "test",
               cutting_time.count,
               run,
               idle,
               stop,
               0,
               logs.count,
               utilization,
               tenant.id,
               cycle_time,
               cutting_time,  
               spindle_load_min.to_s+' - '+spindle_load_max.to_s,
               sp_temp_min.to_s+' - '+sp_temp_max.to_s,
               axis_loadd,
               tempp_val,
               puls_coder,
               feed_rate_max.to_s,
               spindle_speed_max.to_s
            ]




	  end
	  end 
      end

    if @all_data.present?
      @all_data.each do |data|
        if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
        else
          CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
        end
      end
      end 

end
end

