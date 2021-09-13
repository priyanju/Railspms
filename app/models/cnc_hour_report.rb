class CncHourReport < ApplicationRecord
  belongs_to :shift
  belongs_to :operator, -> { with_deleted }, :optional=>true
  belongs_to :machine, -> { with_deleted }
  belongs_to :tenant
  serialize :all_cycle_time, Array 
  serialize :servo_load, Array
  serialize :servo_m_temp, Array
  serialize :puls_code, Array
  serialize :cutting_time, Array

  def self.cnc_hour_report(tenant, shift_no, date)
     date = date
 
  @alldata = []
  #tenants.each do |tenant|
	tenant = Tenant.find(tenant)
	machines = tenant.machines
	
	 shift = tenant.shift.shifttransactions.where(shift_no: shift_no).last
        if tenant.id != 31 || tenant.id != 10
		if shift.shift_start_time.include?("PM") && shift.shift_end_time.include?("AM")
		  if Time.now.strftime("%p") == "AM"
			date = (Date.today - 1).strftime("%Y-%m-%d")
		  end 
		  start_time = (date+" "+shift.shift_start_time).to_time
		  end_time = (date+" "+shift.shift_end_time).to_time+1.day                             
		elsif shift.shift_start_time.include?("AM") && shift.shift_end_time.include?("AM")           
		  if Time.now.strftime("%p") == "AM"
			date = (Date.today - 1).strftime("%Y-%m-%d")
		  end
		  if shift.day == 1
           start_time = (date+" "+shift.shift_start_time).to_time
           end_time = (date+" "+shift.shift_end_time).to_time
         else
           start_time = (date+" "+shift.shift_start_time).to_time+1.day
           end_time = (date+" "+shift.shift_end_time).to_time+1.day
         end
		 # start_time = (date+" "+shift.shift_start_time).to_time+1.day
		 # end_time = (date+" "+shift.shift_end_time).to_time+1.day
		else              
		  start_time = (date+" "+shift.shift_start_time).to_time
		  end_time = (date+" "+shift.shift_end_time).to_time        
		end
	else
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
	end
		
	  #if start_time < Time.now && end_time > Time.now
		
		#loop_count = 1
		(start_time.to_i..end_time.to_i).step(3600) do |hour|
		  (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
		  unless hour_start_time[0].to_time == hour_end_time.to_time
		  machines.order(:id).map do |mac|
			machine_log1 = mac.machine_daily_logs.where("created_at >= ? AND created_at <= ?",hour_start_time[0].to_time,hour_end_time.to_time).order(:id)
			if shift.operator_allocations.where(machine_id:mac.id).last.nil?
			  operator_id = nil
			else
			  if shift.operator_allocations.where(machine_id:mac.id).present?
				shift.operator_allocations.where(machine_id:mac.id).each do |ro| 
				  aa = ro.from_date
				  bb = ro.to_date
				  cc = date
				  if cc.to_date.between?(aa.to_date,bb.to_date)  
					dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
					if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
					  operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id 
					else
					  operator_id = nil
					end              
				  end
				end
			  else
				operator_id = nil
			  end
			end
			job_description = machine_log1.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
			duration = hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i
			new_parst_count = Machine.new_parst_count(machine_log1)
			run_time = Machine.run_time(machine_log1)
			stop_time = Machine.stop_time(machine_log1)
			ideal_time = Machine.ideal_time(machine_log1)
			
			if mac.controller_type == 2
				cycle_time = Machine.rs232_cycle_time(machine_log1)	
			else
				cycle_time = Machine.cycle_time(machine_log1)
			end
			
			count = machine_log1.count
			time_diff = duration - (run_time+stop_time+ideal_time)
			utilization =(run_time*100)/duration if duration.present?
				
			@alldata << [
			  date,
			  hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1],
			  duration,
			  shift.shift.id,
			  shift.shift_no,
			  operator_id,
			  mac.id,
			  job_description.nil? ? "-" : job_description.split(',').join(" & "),
			  new_parst_count,
			  run_time,
			  ideal_time,
			  stop_time,
			  time_diff,
			  count,
			  utilization,
			  tenant.id,
			  cycle_time
			  ]  
		  end
		#end
	 end    
	#end
  end
  @alldata.each do |data|
		if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
		  CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16])
		else
		    #  if CncHourReport.where(machine_id:data[6], tenant_id:data[15]).present?
			  # if data[4] == 1
			  #   shift = Tenant.find(data[15]).shift.shifttransactions.last.shift_no
			  #   date = Date.yesterday.strftime("%Y-%m-%d")
			  # else
			  #   shift = data[4] - 1
			  #   date = data[0]
			  # end
			  # cnc_last_report = CncHourReport.last_hour_report(date, data[6], data[15], shift)
		   #  end
		  CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16])
		end
  end 
end


  
    def self.cnc_hour_report1(tenant, shift_no, date)
   date = date
   @alldata = []
   tenant = Tenant.find(tenant)
   machines = tenant.machines.where(controller_type: [1,5,2])
   shift = tenant.shift.shifttransactions.where(shift_no: shift_no).last

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

           (start_time.to_i..end_time.to_i).step(3600) do |hour|
          (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
          unless hour_start_time[0].to_time == hour_end_time.to_time
            machines.order(:id).map do |mac|
                    machine_log1 = mac.machine_daily_logs.where("created_at >= ? AND created_at <= ?",hour_start_time[0].to_time,hour_end_time.to_time).order(:id)
                          if shift.operator_allocations.where(machine_id:mac.id).last.nil?
                            operator_id = nil
                          else
                                  if shift.operator_allocations.where(machine_id:mac.id).present?
                                          shift.operator_allocations.where(machine_id:mac.id).each do |ro|
                                                  aa = ro.from_date
                                                  bb = ro.to_date
                                                  cc = date
                                            if cc.to_date.between?(aa.to_date,bb.to_date)
                                                    dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
                                                    if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
                                                      operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id
                                                    else
                                                      operator_id = nil
                                                    end
                                            end
                                          end
                                  else
                                          operator_id = nil
                                  end
                          end


                     job_description = machine_log1.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
                                duration = hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i
                                new_parst_count = Machine.new_parst_count1(machine_log1)
                                

                       #        new_parst_count = Shift.new_parst_count1000(machine_log1)
                                run_time = Machine.run_time(machine_log1)
                                stop_time = Machine.stop_time(machine_log1)
                                ideal_time = Machine.ideal_time(machine_log1)

                        #       cycle_time = Machine.cycle_time25(machine_log1)
                                 if mac.controller_type == 1
                                   cycle_time = Machine.cycle_time15(machine_log1)
                                 else
                                   cycle_time = Machine.rs232_cycle_time15(machine_log1)
                                 end
                #        cycle_time = Shift.cycle_time2000(machine_log1)
                           


                              cutting_time = Shift.cutting_time(machine_log1)
		#	byebug
     #  feed_rate_min = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).min
       feed_rate_max = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
       	
     #  spindle_speed_min = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
       spindle_speed_max = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
			

      sp_temp_min = machine_log1.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
      sp_temp_max = machine_log1.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

      spindle_load_min = machine_log1.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
      spindle_load_max = machine_log1.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
			
      
      data_val = MachineSettingList.where(machine_setting_id: MachineSetting.find_by(machine_id: mac.id).id,is_active: true).pluck(:setting_name)
       
       axis_loadd = []
       tempp_val = []
       puls_coder = []
     
      if machine_log1.present?
      unless mac.controller_type == 2
      machine_log1.last.x_axis.first.each_with_index do |key, index|
        if data_val.include?(key[0].to_s)
       # key = 0
          load_value =  machine_log1.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+machine_log1.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
          temp_value =  machine_log1.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+machine_log1.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
          puls_value =  machine_log1.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+machine_log1.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
          
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
     end
  end                               


                                count = machine_log1.count
                                time_diff = duration - (run_time+stop_time+ideal_time)
                                utilization =(run_time*100)/duration if duration.present?

                                @alldata << [
                                  date,
                                  hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1],
                                  duration,
                                  shift.shift.id,
                                  shift.shift_no,
                                  operator_id,
                                  mac.id,
                                  job_description.nil? ? "-" : job_description.split(',').join(" & "),
                                  new_parst_count,
                                  run_time,
                                  ideal_time,
                                  stop_time,
                                  time_diff,
                                  count,
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


   if @alldata.present?
          @alldata.each do |data|
                  if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
                  CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
                else
                  CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
                end

           end
         end
end

  def self.cnc_hour_report01
  date = Date.today.strftime("%Y-%m-%d")
  #date="2018-08-31"
  tenants = Tenant.where(id: [8]).ids
  #tenants = Tenant.where(isactive: true).ids
  @alldata = []
  tenants.each do |tenant|
	tenant = Tenant.find(tenant)
	machines = tenant.machines
	#shifts = tenant.shift.shifttransactions.ids
	#shifts.each do |shift_id|
	 shift = Shifttransaction.find(3)
	  #shift = Shifttransaction.current_shift(tenant.id)
		if shift.shift_start_time.include?("PM") && shift.shift_end_time.include?("AM")
		  if Time.now.strftime("%p") == "AM"
			date = (Date.today - 1).strftime("%Y-%m-%d")
		  end 
		  start_time = (date+" "+shift.shift_start_time).to_time
		  end_time = (date+" "+shift.shift_end_time).to_time+1.day                             
		elsif shift.shift_start_time.include?("AM") && shift.shift_end_time.include?("AM")           
		  if Time.now.strftime("%p") == "AM"
			date = (Date.today - 1).strftime("%Y-%m-%d")
		  end

		  if shift.day == 1
           start_time = (date+" "+shift.shift_start_time).to_time
           end_time = (date+" "+shift.shift_end_time).to_time
         else
           start_time = (date+" "+shift.shift_start_time).to_time+1.day
           end_time = (date+" "+shift.shift_end_time).to_time+1.day
         end

		 # start_time = (date+" "+shift.shift_start_time).to_time+1.day
		 # end_time = (date+" "+shift.shift_end_time).to_time+1.day
		else              
		  start_time = (date+" "+shift.shift_start_time).to_time
		  end_time = (date+" "+shift.shift_end_time).to_time        
		end
		
	  #if start_time < Time.now && end_time > Time.now
		
		#loop_count = 1
		(start_time.to_i..end_time.to_i).step(3600) do |hour|
		  (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
		  unless hour_start_time[0].to_time == hour_end_time.to_time
		  machines.order(:id).map do |mac|
			machine_log1 = mac.machine_daily_logs.where("created_at >= ? AND created_at <= ?",hour_start_time[0].to_time,hour_end_time.to_time).order(:id)
			if shift.operator_allocations.where(machine_id:mac.id).last.nil?
			  operator_id = nil
			else
			  if shift.operator_allocations.where(machine_id:mac.id).present?
				shift.operator_allocations.where(machine_id:mac.id).each do |ro| 
				  aa = ro.from_date
				  bb = ro.to_date
				  cc = date
				  if cc.to_date.between?(aa.to_date,bb.to_date)  
					dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
					if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
					  operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id 
					else
					  operator_id = nil
					end              
				  end
				end
			  else
				operator_id = nil
			  end
			end
			job_description = machine_log1.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
			duration = hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i
			new_parst_count = Machine.new_parst_count(machine_log1)
			run_time = Machine.run_time(machine_log1)
			stop_time = Machine.stop_time(machine_log1)
			ideal_time = Machine.ideal_time(machine_log1)
			cycle_time = Machine.cycle_time(machine_log1)
			count = machine_log1.count
			time_diff = duration - (run_time+stop_time+ideal_time)
			utilization =(run_time*100)/duration if duration.present?
				
			@alldata << [
			  date,
			  hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1],
			  duration,
			  shift.shift.id,
			  shift.shift_no,
			  operator_id,
			  mac.id,
			  job_description.nil? ? "-" : job_description.split(',').join(" & "),
			  new_parst_count,
			  run_time,
			  ideal_time,
			  stop_time,
			  time_diff,
			  count,
			  utilization,
			  tenant.id,
			  cycle_time
			  ]  
		  end
		#end
	 end    
	end
  end
  @alldata.each do |data|
		if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
		  CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16])
		else
		  CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16])
		end
  end 
end

def self.shift_change
	tenant = Tenant.find(8)
	shifts = tenant.shift.shifttransactions
	shifts.each do |shift|
		if shift.day == 1
			date = Date.today.
	  else
	  end
		  start_time = (date+" "+shift.shift_start_time).to_time
		  end_time = (date+" "+shift.shift_end_time).to_time 
		shift
	end
end






  def self.cnc_hour_report_speed
    tenants = Tenant.where(id: 8)
    tenants.each do |tenant|
     @alldata = []
     date = Date.today.strftime("%Y-%m-%d")
	  tenant = Tenant.find(tenant)
	  machines = tenant.machines
	  shift = Shifttransaction.current_shift(tenant.id)

  if tenant.id != 31 || tenant.id != 10
		if shift.shift_start_time.include?("PM") && shift.shift_end_time.include?("AM")
		  if Time.now.strftime("%p") == "AM"
			date = (Date.today - 1).strftime("%Y-%m-%d")
		  end 
		  start_time = (date+" "+shift.shift_start_time).to_time
		  end_time = (date+" "+shift.shift_end_time).to_time+1.day                             
		elsif shift.shift_start_time.include?("AM") && shift.shift_end_time.include?("AM")           
		  if Time.now.strftime("%p") == "AM"
			date = (Date.today - 1).strftime("%Y-%m-%d")
		  end
		  if shift.day == 1
           start_time = (date+" "+shift.shift_start_time).to_time
           end_time = (date+" "+shift.shift_end_time).to_time
         else
           start_time = (date+" "+shift.shift_start_time).to_time+1.day
           end_time = (date+" "+shift.shift_end_time).to_time+1.day
         end
		 # start_time = (date+" "+shift.shift_start_time).to_time+1.day
		 # end_time = (date+" "+shift.shift_end_time).to_time+1.day
		else              
		  start_time = (date+" "+shift.shift_start_time).to_time
		  end_time = (date+" "+shift.shift_end_time).to_time        
		end
	else
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
	end
		
	  #if start_time < Time.now && end_time > Time.now
		
		#loop_count = 1
		(start_time.to_i..end_time.to_i).step(3600) do |hour|
		  (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
		  unless hour_start_time[0].to_time == hour_end_time.to_time
		  machines.order(:id).map do |mac|
			machine_log1 = mac.machine_daily_logs.where("created_at >= ? AND created_at <= ?",hour_start_time[0].to_time,hour_end_time.to_time).order(:id)
			if shift.operator_allocations.where(machine_id:mac.id).last.nil?
			  operator_id = nil
			else
			  if shift.operator_allocations.where(machine_id:mac.id).present?
				shift.operator_allocations.where(machine_id:mac.id).each do |ro| 
				  aa = ro.from_date
				  bb = ro.to_date
				  cc = date
				  if cc.to_date.between?(aa.to_date,bb.to_date)  
					dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
					if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
					  operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id 
					else
					  operator_id = nil
					end              
				  end
				end
			  else
				operator_id = nil
			  end
			end
			job_description = machine_log1.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
			duration = hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i
			new_parst_count = Machine.new_parst_count(machine_log1)
			run_time = Machine.run_time(machine_log1)
			stop_time = Machine.stop_time(machine_log1)
			ideal_time = Machine.ideal_time(machine_log1)
			
			if mac.controller_type == 2
				cycle_time = Machine.rs232_cycle_time(machine_log1)	
			else
				cycle_time = Machine.cycle_time(machine_log1)
			end
			
			count = machine_log1.count
			time_diff = duration - (run_time+stop_time+ideal_time)
			utilization =(run_time*100)/duration if duration.present?
				
			@alldata << [
			  date,
			  hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1],
			  duration,
			  shift.shift.id,
			  shift.shift_no,
			  operator_id,
			  mac.id,
			  job_description.nil? ? "-" : job_description.split(',').join(" & "),
			  new_parst_count,
			  run_time,
			  ideal_time,
			  stop_time,
			  time_diff,
			  count,
			  utilization,
			  tenant.id,
			  cycle_time
			  ]  
		  end
		#end
	 end    
	end
  end
  @alldata.each do |data|
		if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
		  CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16])
		else
		  CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16])
		end
  end 
end




   def self.cnc_report_simple_query1(tenant, shift_no, date)
    date = date
    @alldata = []
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
    
   
      machine_log11 = MachineDailyLog.includes(:machine).where(created_at: start_time..end_time, machines: {tenant_id: tenant, controller_type: 1}).group_by{|x| x.machine_id}
      
      machine_ids = Tenant.find(tenant).machines.where(controller_type: 1).pluck(:id)
      mac_ids = machine_log11.keys 
      bls = machine_ids - mac_ids
      mer_req = bls.map{|i| [i,[]]}.to_h
      machine_log = machine_log11.merge(mer_req)
      
      #data = machine_log.group_by(&:machine_id) 
      
    machine_log.each do |key, value|
      job_description = value.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
      ff = value.group_by{|i| [i.parts_count, i.programe_number]}
      run_time = Machine.run_time(value)
      stop_time = Machine.stop_time(value)
      ideal_time = Machine.ideal_time(value)
     
      part_time = Shift.parts_time(value)
      #start_time = Shifttransaction.time(value)
      
      duration = (end_time - start_time).to_i
      time_diff = duration - (run_time+stop_time+ideal_time)
      utilization =(run_time*100)/duration if duration.present?

      if shift.operator_allocations.where(machine_id: key).last.nil?
        operator_id = nil
        target = 0
      else
        if shift.operator_allocations.where(machine_id: key).present?
          shift.operator_allocations.where(machine_id: key).each do |ro|
            aa = ro.from_date
            bb = ro.to_date
            cc = date
            if cc.to_date.between?(aa.to_date,bb.to_date)
              dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
              if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
                operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id
                target = dd.operator_mapping_allocations.where(:date=>date.to_date).last.target
              else
                operator_id = nil
                target = 0
              end
            else
              operator_id = nil
              target = 0
            end
          end
        else
          operator_id = nil
          target = 0
        end
      end

      data4 = ShiftPart.where(date: date, machine_id:key, shift_no: shift.shift_no)
      data_parts_count = data4.count
      approved = data4.where(status: 1).count
      rework = data4.where(status: 2).count
      rejected = data4.where(status: 3).count

      if target == 0
        pending = 0
      else
        pending = target - data_parts_count
      end


    # feed_rate_min = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).min
      feed_rate_max = value.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
       
    # spindle_speed_min = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
      spindle_speed_max = value.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
      
      sp_temp_min = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
      sp_temp_max = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

      spindle_load_min = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
      spindle_load_max = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

     
      mac_setting_id =  MachineSetting.find_by(machine_id: key).id     
      data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)
       
      axis_loadd = []
      tempp_val = []
      puls_coder = []
      
      if value.present?
        unless value.first.machine.controller_type == 2
          value.last.x_axis.first.each_with_index do |key, index|
            if data_val.include?(key[0].to_s)
              # key = 0
              load_value =  value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
              temp_value =  value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
              puls_value =  value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
              
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
        end
      end

      oee_perfomance = []
      oee_qty = []

      if OeeCalculation.where(date: date, machine_id: key, shifttransaction_id: shift.id).present?
        oee_part = OeeCalculation.where(date: date, machine_id: key, shifttransaction_id: shift.id).last.oee_calculate_lists       
        oee_part.each do |pgn|  
          oee_perfomance << (pgn.run_rate.to_i * pgn.parts_count.to_i)/(pgn.time.to_i).to_f
          shift_part_count = ShiftPart.where(date: date, machine_id: key, shifttransaction_id: shift.id, program_number: pgn.program_number) 
          if shift_part_count.count == 0
            oee_qty << 0
          else
            good_pieces = shift_part_count.where(status: 1).count
            oee_qty << (good_pieces)/(pgn.parts_count.to_i).to_f
          end
        end
      else
        oee_perfomance = [0]
        oee_qty = [0]
      end
       
      avialabilty = 1
      perfomance = oee_perfomance.inject{ |sum, el| sum + el }.to_f / oee_perfomance.size
      quality = oee_qty.inject{ |sum, el| sum + el }.to_f / oee_qty.size
        
     @alldata << [
               
                date,
                start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"),
                duration,
                shift.shift.id,
                shift.shift_no,
                operator_id,#(operator)
                key, #(machine_id)
                job_description.nil? ? "-" : job_description.split(',').join(" & "),
                part_time[:cutting_time].count,
                run_time,
                ideal_time,
                stop_time,
                time_diff,
                value.count,
                utilization,
                tenant.to_i,
                part_time[:cycle_time],
                [],# start_cycle_time,
                feed_rate_max.to_s,
                spindle_speed_max.to_s,
                data_parts_count,
                target,
                pending,
                approved,
                rework,
                rejected,
                [],# stop_to_start,
                part_time[:cutting_time],
                spindle_load_min.to_s+' - '+spindle_load_max.to_s,
                sp_temp_min.to_s+' - '+sp_temp_max.to_s,
                axis_loadd,
                tempp_val,
                puls_coder,
                avialabilty,
                perfomance,
                quality                  
     ]
    end
     #return @alldata

    if @alldata.present?
      @alldata.each do |data|
        if CncReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          CncReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16], cycle_start_to_start: data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: 0, perfomance: data[34], quality: data[35])
        else
          CncReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16], cycle_start_to_start:data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: data[33], perfomance: data[34], quality: data[35])
        end
      end
    end
  
  end



def self.cnc_report_simple_query_hour1(tenant, shift_no, date)
  date = date
    @alldata = []
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
      
      (start_time.to_i..end_time.to_i).step(3600) do |hour|
        (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
        unless hour_start_time[0].to_time == hour_end_time.to_time          
           machine_log = MachineDailyLog.includes(:machine).where(created_at: hour_start_time[0].to_time..hour_end_time.to_time, machines: {tenant_id: tenant}).group_by{|x| x.machine_id}
           machine_log.each do |key, value|
           
            run_time = Machine.run_time(value)
            stop_time = Machine.stop_time(value)
            ideal_time = Machine.ideal_time(value)
            part_time = Shift.parts_time(value)

            job_description = value.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
            duration = hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i

            time_diff = duration - (run_time+stop_time+ideal_time)
            utilization =(run_time*100)/duration if duration.present?
            
           

            if shift.operator_allocations.where(machine_id: key).last.nil?
        operator_id = nil
        target = 0
      else
        if shift.operator_allocations.where(machine_id: key).present?
          shift.operator_allocations.where(machine_id: key).each do |ro|
            aa = ro.from_date
            bb = ro.to_date
            cc = date
            if cc.to_date.between?(aa.to_date,bb.to_date)
              dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
              if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
                operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id
                target = dd.operator_mapping_allocations.where(:date=>date.to_date).last.target
              else
                operator_id = nil
                target = 0
              end
            else
              operator_id = nil
              target = 0
            end
          end
        else
          operator_id = nil
          target = 0
        end
      end





            
            # feed_rate_min = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).min
            feed_rate_max = value.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
             
          # spindle_speed_min = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            spindle_speed_max = value.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
            
            sp_temp_min = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            sp_temp_max = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

            spindle_load_min = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            spindle_load_max = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

           
            mac_setting_id =  MachineSetting.find_by(machine_id: key).id     
            data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)
             
            axis_loadd = []
            tempp_val = []
            puls_coder = []
            
            if value.present?
              unless value.first.machine.controller_type == 2
                value.last.x_axis.first.each_with_index do |key, index|
                  if data_val.include?(key[0].to_s)
                    # key = 0
                    load_value =  value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    temp_value =  value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    puls_value =  value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    
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
              end
            end




              
            @alldata << [
               date,
               hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1],
               duration,
               shift.shift.id,
               shift.shift_no,
               operator_id,
               key,
               job_description.nil? ? "-" : job_description.split(',').join(" & "),
               part_time[:cutting_time].count,
               run_time,
               ideal_time,
               stop_time,
               time_diff,
               value.count,
               utilization,
               tenant.to_i,
               part_time[:cycle_time],
               part_time[:cutting_time],  
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
    
     if @alldata.present?
      @alldata.each do |data|
        if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
        else
          CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
        end
      end

      end 
    #byebug


    # if @alldata.present?
    #   @alldata.each do |data|
    #     if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
    #       CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
    #     else
    #       CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[16],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
    #     end
    #   end
    # end

end




   def self.cnc_report_simple_query(tenant, shift_no, date)
#byebug
    date = date
    date2 = date.to_date.strftime("%Y-%m-%d %H:%M:%S")
    @alldata = []
    send_part = []
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
      
      machine_ids = Tenant.find(tenant).machines.where(controller_type: 1).pluck(:id)

      full_log2 = MachineDailyLog.where(machine_id: machine_ids)#.group_by{|x| x.machine_id} ##1##
      full_log = full_log2.group_by{|x| x.machine_id}
      #full_log = ExternalMachineDailyLog.includes(:machine).where(machines: {tenant_id: tenant, controller_type: 1}).group_by{|x| x.machine_id} ##1##
      machine_log11 = full_log2.select{|a| a[:created_at] >= start_time && a[:created_at] < end_time}.group_by{|x| x.machine_id}
      #machine_log11 = full_log2.where(created_at: start_time..(end_time-1)).group_by{|x| x.machine_id}
      
      mac_ids = machine_log11.keys 
      bls = machine_ids - mac_ids
      mer_req = bls.map{|i| [i,[]]}.to_h
      
      machine_log = machine_log11.merge(mer_req)
      full_logs = full_log.merge(mer_req) ##1##
      #data = machine_log.group_by(&:machine_id) 
      
       machine_log.each do |key, value|
        value1 = full_logs[key]
        job_description = value.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
        ff = value.group_by{|i| [i.parts_count, i.programe_number]}

        run_time = Machine.run_time(value)
        stop_time = Machine.stop_time(value)
        ideal_time = Machine.ideal_time(value)

        #part_time = Shift.parts_time3(value, value1)
        @part_time = BreakTime.parts_time3(value, value1,shift_no,shift.id, date)
        send_part << @part_time
    
        part_time1 = @part_time.select{|a| a[:time] >= start_time && a[:time] < end_time }
   # byebug   
        cycle_st_to_st = part_time1.pluck(:cycle_st_to_st).map{|i| i.to_i}
        cutting_time = part_time1.pluck(:cutting_time).map{|i| i.to_i}
        cycle_stop_to_stop = part_time1.pluck(:cycle_stop_to_stop).map{|i| i.to_i}
#byebug
        cycle_time = part_time1.pluck(:cycle_time).flatten        
        a = []
	cycle_time.each do |i|      
	a << eval(i)
	end
  
      #  cycle_st_to_st = @part_time.pluck(:cycle_st_to_st).map{|i| i.to_i}
      #  cutting_time = @part_time.pluck(:cutting_time).map{|i| i.to_i}
      #  cycle_stop_to_stop = @part_time.pluck(:cycle_stop_to_stop).map{|i| i.to_i}
      #  cycle_time = @part_time.pluck(:cycle_time).flatten
      #  start_time = Shifttransaction.time(value)
        
        duration = (end_time - start_time).to_i
        time_diff = duration - (run_time+stop_time+ideal_time)
        utilization =(run_time*100)/duration if duration.present?
  #########3sofiya

                  total_target = []
		  multiple_target_data = []
		  operator_detail = OperatorAllocation.where(machine_id:key, shifttransaction_id:shift.id,date:date2)
                  
                	if operator_detail.present?
#byebug
			operator_id = operator_detail.last.operator_allot_details.pluck(:operator_id)
		#	operator_id = operator_detail.last.operator_allot_details.pluck(:operator_id, :operation_management_id)
                        operator_detail.last.operator_allot_details.each do |i|
			
                        total_cycle_time = i.operation_management.std_cycle_time.to_i + i.operation_management.load_unload_time.to_i
			target_value = (i.end_time.to_i - i.start_time.to_i)/total_cycle_time
		 	part_time1 = @part_time.select{|a| a[:time] >= i.start_time.to_time && a[:time] < i.end_time.to_time }
			actual_part = cutting_time.count
			@actual_parts_count = actual_part
			total_target << target_value
                       end
                     else
                        operator_id = []
                        total_target = []
			multiple_target_data = []
			@actual_parts_count = 0
#			target = 0
               	    end
        	        target = total_target.sum
		
#####################
#                 alloc_data = OperatorAllocation.where(shifttransaction_id: shift.id, machine_id: key, date: date2)
#                allocation_detail = []
#                 if alloc_data.present?
 #                   op_detail = alloc_data.last.operator_allot_details
  #               if op_detail.present?
   #                 op_name = op_detail.last.operator.operator_name
    #                op_detail.each do |op_li|
     #                      single_part_time = op_li.operation_management.std_cycle_time + op_li.operation_management.load_unload_time
      #                     running_hour = (op_li.end_time - op_li.start_time).to_i
       #                    target = (running_hour/single_part_time).to_i
        #                   part = full_parts.select{|b|b.machine_id == key && b.cycle_start != nil && b.part_end_time >= op_li.start_time && b.part_end_time < op_li.end_time-1}
         #                  allocation_detail << {target:target,operator_id:op_li.operator_id,operation_id:op_li.operation_management_id,parts_produced:part.count,start_time:op_li.start_time.localtime,end_time:op_li.end_time.localtime}
#
 #                   end
  #               else
   #              end
    #             else
     #            end
####################
        data4 = ShiftPart.where(date: date, machine_id:key, shift_no: shift.shift_no)
        data_parts_count = data4.count
        approved = data4.where(status: 1).count
        rework = data4.where(status: 2).count
        rejected = data4.where(status: 3).count

        if target == 0 || target == nil
          pending = 0
        else
          pending = target - data_parts_count
        end

      # feed_rate_min = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).min
        feed_rate_max = value.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
         
      # spindle_speed_min = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        spindle_speed_max = value.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
        
        sp_temp_min = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        sp_temp_max = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

        spindle_load_min = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        spindle_load_max = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

        mac_setting_id =  MachineSetting.find_by(machine_id: key).id     
        data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)
         
        axis_loadd = []
        tempp_val = []
        puls_coder = []
        
        if value.present?
          unless value.first.machine.controller_type == 2
            value.last.x_axis.first.each_with_index do |key, index|
              if data_val.include?(key[0].to_s)
                # key = 0
                load_value =  value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                temp_value =  value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                puls_value =  value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                
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
          end
        end

         ## OEE START ##

        oee_perfomance = []
        oee_qty = []

        if OeeCalculation.where(date: date, machine_id: key, shifttransaction_id: shift.id).present?
          oee_part = OeeCalculation.where(date: date, machine_id: key, shifttransaction_id: shift.id).last.oee_calculate_lists       
          oee_part.each do |pgn|  
            oee_perfomance << (pgn.run_rate.to_i * pgn.parts_count.to_i)/(pgn.time.to_i).to_f
            shift_part_count = ShiftPart.where(date: date, machine_id: key, shifttransaction_id: shift.id, program_number: pgn.program_number) 
            if shift_part_count.count == 0
              oee_qty << 0
            else
              good_pieces = shift_part_count.where(status: 1).count
              oee_qty << (good_pieces)/(pgn.parts_count.to_i).to_f
            end
          end
        else
          oee_perfomance = [0]
          oee_qty = [0]
        end
         
        avialabilty = 1
        perfomance = oee_perfomance.inject{ |sum, el| sum + el }.to_f / oee_perfomance.size
        quality = oee_qty.inject{ |sum, el| sum + el }.to_f / oee_qty.size
          
        ## OEE END ##    


       @alldata << [
                 
        date,	#data[0]
	start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"), #data[1]
        duration, #data[2]
        shift.shift.id, #data[3]
        shift.shift_no, #data[4]
        operator_id,#(operator) #data[5]
        key, #(machine_id) #data[6]
        job_description.nil? ? "-" : job_description.split(',').join(" & "), #data[7]
        cutting_time.count, #data[8]
        run_time, #data[9]
        ideal_time, #data[10]
        stop_time, #data[11]
        time_diff, #data[12]
        value.count, #data[13]
        utilization, #data[14]
        tenant.to_i, #data[15]
        cycle_time, #data[16]
        cycle_st_to_st, #data[17]
        feed_rate_max.to_s, #data[18]
        spindle_speed_max.to_s, #data[19]
        data_parts_count, #data[20]
        target, #data[21]
        pending, #data[22]
        approved, #data[23]
        rework, #data[24]
        rejected, #data[25]
        cycle_stop_to_stop, #data[26]
        cutting_time, #data[27]
        spindle_load_min.to_s+' - '+spindle_load_max.to_s, #data[28]
        sp_temp_min.to_s+' - '+sp_temp_max.to_s, #data[29]
        axis_loadd, #data[30]
        tempp_val, #data[31]
        puls_coder, #data[32]
        avialabilty, #data[33]
        perfomance, #data[34]
        quality,    #data[35]              
	a
       ]
      #end 
    end
     #return @alldata

    if @alldata.present?
      @alldata.each do |data|
	
	 if data[5].present?
		data[5].each do |i|

        	 if CncReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          	    CncReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: [], cycle_start_to_start: data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: 0, perfomance: data[34], quality: data[35], parts_data: data[36])
	         else
         	    CncReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: [], cycle_start_to_start:data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: data[33], perfomance: data[34], quality: data[35],parts_data: data[36])
        	end
	       end
	else
	        if CncReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
                    CncReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: [], cycle_start_to_start: data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: 0, perfomance: data[34], quality: data[35], parts_data: data[36])
                 else
                    CncReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: [], cycle_start_to_start:data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: data[33], perfomance: data[34], quality: data[35],parts_data: data[36])
                end
	end
      end
    end
  byebug
  data = CncHourReport.cnc_report_simple_query_hour_vino(tenant, shift_no, date, send_part)
  puts 'ok'
  end



   def self.cnc_report_simple_query_new1(tenant, shift_no, date)
    date = date
    @alldata = []
    send_part = []
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
      
      machine_ids = Tenant.find(tenant).machines.where(controller_type: 1).pluck(:id)

      full_log2 = MachineDailyLog.where(machine_id: machine_ids)#.group_by{|x| x.machine_id} ##1##
      full_log = full_log2.group_by{|x| x.machine_id}
      #full_log = ExternalMachineDailyLog.includes(:machine).where(machines: {tenant_id: tenant, controller_type: 1}).group_by{|x| x.machine_id} ##1##
      machine_log11 = full_log2.select{|a| a[:created_at] >= start_time && a[:created_at] < end_time}.group_by{|x| x.machine_id}
      #machine_log11 = full_log2.where(created_at: start_time..(end_time-1)).group_by{|x| x.machine_id}
      
      mac_ids = machine_log11.keys 
      bls = machine_ids - mac_ids
      mer_req = bls.map{|i| [i,[]]}.to_h
      
      machine_log = machine_log11.merge(mer_req)
      full_logs = full_log.merge(mer_req) ##1##
      #data = machine_log.group_by(&:machine_id) 
      
       machine_log.each do |key, value|
        value1 = full_logs[key]
        job_description = value.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
        ff = value.group_by{|i| [i.parts_count, i.programe_number]}
        
        tot_time_res = Machine.new_run_time(value, value1, start_time, end_time)
        
        run_time = tot_time_res[:run_time]
        stop_time = tot_time_res[:stop_time]
        ideal_time = tot_time_res[:idle_time]
       
        #part_time = Shift.parts_time3(value, value1)

        @part_time = BreakTime.parts_time3(value, value1,shift_no,shift.id, date)
        
        send_part << @part_time
        
       part_time1 = @part_time.select{|a| a[:time] >= start_time && a[:time] < end_time }
        
        cycle_st_to_st = part_time1.pluck(:cycle_st_to_st).map{|i| i.to_i}
        cutting_time = part_time1.pluck(:cutting_time).map{|i| i.to_i}
        cycle_stop_to_stop = part_time1.pluck(:cycle_stop_to_stop).map{|i| i.to_i}
        cycle_time = part_time1.pluck(:cycle_time).flatten        



        
      #  cycle_st_to_st = @part_time.pluck(:cycle_st_to_st).map{|i| i.to_i}
      #  cutting_time = @part_time.pluck(:cutting_time).map{|i| i.to_i}
      #  cycle_stop_to_stop = @part_time.pluck(:cycle_stop_to_stop).map{|i| i.to_i}
      #  cycle_time = @part_time.pluck(:cycle_time).flatten
        #start_time = Shifttransaction.time(value)
        
        duration = (end_time - start_time).to_i
        time_diff = duration - (run_time+stop_time+ideal_time)
        utilization =(run_time*100)/duration if duration.present?

        if shift.operator_allocations.where(machine_id: key).last.nil?
          operator_id = nil
          target = 0
        else
          if shift.operator_allocations.where(machine_id: key).present?
            shift.operator_allocations.where(machine_id: key).each do |ro|
              aa = ro.from_date
              bb = ro.to_date
              cc = date
              if cc.to_date.between?(aa.to_date,bb.to_date)
                dd = ro#cc.to_date.between?(aa.to_date,bb.to_date)
                if dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.present?
                  operator_id = dd.operator_mapping_allocations.where(:date=>date.to_date).last.operator.id
                  target = dd.operator_mapping_allocations.where(:date=>date.to_date).last.target
                else
                  operator_id = nil
                  target = 0
                end
              else
                operator_id = nil
                target = 0
              end
            end
          else
            operator_id = nil
            target = 0
          end
        end

        data4 = ShiftPart.where(date: date, machine_id:key, shift_no: shift.shift_no)
        data_parts_count = data4.count
        approved = data4.where(status: 1).count
        rework = data4.where(status: 2).count
        rejected = data4.where(status: 3).count

        if target == 0 || target == nil
          pending = 0
        else
          pending = target - data_parts_count
        end


      # feed_rate_min = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).min
        feed_rate_max = value.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
         
      # spindle_speed_min = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        spindle_speed_max = value.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
        
        sp_temp_min = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        sp_temp_max = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

        spindle_load_min = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
        spindle_load_max = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

        mac_setting_id =  MachineSetting.find_by(machine_id: key).id     
        data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)
         
        axis_loadd = []
        tempp_val = []
        puls_coder = []
        
        if value.present?
          unless value.first.machine.controller_type == 2
            value.last.x_axis.first.each_with_index do |key, index|
              if data_val.include?(key[0].to_s)
                # key = 0
                load_value =  value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                temp_value =  value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                puls_value =  value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                
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
          end
        end

         ## OEE START ##

        oee_perfomance = []
        oee_qty = []

        if OeeCalculation.where(date: date, machine_id: key, shifttransaction_id: shift.id).present?
          oee_part = OeeCalculation.where(date: date, machine_id: key, shifttransaction_id: shift.id).last.oee_calculate_lists       
          oee_part.each do |pgn|  
            oee_perfomance << (pgn.run_rate.to_i * pgn.parts_count.to_i)/(pgn.time.to_i).to_f
            shift_part_count = ShiftPart.where(date: date, machine_id: key, shifttransaction_id: shift.id, program_number: pgn.program_number) 
            if shift_part_count.count == 0
              oee_qty << 0
            else
              good_pieces = shift_part_count.where(status: 1).count
              oee_qty << (good_pieces)/(pgn.parts_count.to_i).to_f
            end
          end
        else
          oee_perfomance = [0]
          oee_qty = [0]
        end
         
        avialabilty = 1
        perfomance = oee_perfomance.inject{ |sum, el| sum + el }.to_f / oee_perfomance.size
        quality = oee_qty.inject{ |sum, el| sum + el }.to_f / oee_qty.size
          
        ## OEE END ##    


       @alldata << [
                 
        date, #data[0]
        start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"), #data[1]
        duration, #data[2]
        shift.shift.id, #data[3]
        shift.shift_no, #data[4]
        operator_id,#(operator) #data[5]
        key, #(machine_id) data[6]
        job_description.nil? ? "-" : job_description.split(',').join(" & "), #data[7]
        cutting_time.count, #data[8]
        run_time, #data[9]
        ideal_time, #data[10]
        stop_time, #data[11]
        time_diff, #data[12]
        value.count, #data[13]
        utilization, #data[14]
        tenant.to_i, #data[15]
        cycle_time, #data[16]
        cycle_st_to_st, #data[17]
        feed_rate_max.to_s, #data[18]
        spindle_speed_max.to_s, #data[19]
        data_parts_count, #data[20]
        target, #data[21]
        pending, #data[22]
        approved, #data[23]
        rework, #data[24]
        rejected, #data[25]
        cycle_stop_to_stop, #data[26]
        cutting_time, #data[27]
        spindle_load_min.to_s+' - '+spindle_load_max.to_s, #data[28]
        sp_temp_min.to_s+' - '+sp_temp_max.to_s, #data[29]
        axis_loadd, #data[30]
        tempp_val, #data[31]
        puls_coder, #data[32]
        avialabilty, #data[33]
        perfomance, #data[34]
        quality     #data[35]     
       ]
      #end 
    end
     #return @alldata

    if @alldata.present?

      @alldata.each do |data|
        if CncReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          CncReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: [], cycle_start_to_start: data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: 0, perfomance: data[34], quality: data[35], parts_data: data[16])
        else
          CncReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], idle_time: data[10], stop_time: data[11], time_diff: data[12], utilization: data[14],  tenant_id: data[15], all_cycle_time: [], cycle_start_to_start:data[17], feed_rate: data[18], spendle_speed: data[19], data_part: data[20], target:data[21], approved: data[23], rework: data[24], reject: data[25], stop_to_start: data[26], cutting_time: data[27],spindle_load: data[28], spindle_m_temp: data[29], servo_load: data[30], servo_m_temp: data[31], puls_code: data[32],availability: data[33], perfomance: data[34], quality: data[35],parts_data: data[16])
        end
      end
    end
  data = CncHourReport.cnc_report_simple_query_hour(tenant, shift_no, date, send_part)
  puts 'ok'
  end



def self.cnc_report_simple_query_hour(tenant, shift_no, date, data)
#byebug
  date = date
  date2 = date.to_date.strftime("%Y-%m-%d %H:%M:%S")
    @alldata = []
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
      
      machine_ids = Tenant.find(tenant).machines.where(controller_type: 1).pluck(:id)

      #full_log = MachineDailyLog.includes(:machine).where(machines: {tenant_id: tenant, controller_type: 1}).group_by{|x| x.machine_id} 
      full_logs = MachineDailyLog.where(machine_id: machine_ids).group_by{|x| x.machine_id} ##1##


      (start_time.to_i..end_time.to_i).step(3600) do |hour|
#byebug
        (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
	
#         hour_strt_time = hour_start_time.strftime("")	

        unless hour_start_time[0].to_time == hour_end_time.to_time         
#byebug 
           machine_log = MachineDailyLog.where(created_at: hour_start_time[0].to_time..(hour_end_time.to_time-1), machine_id: machine_ids).group_by{|x| x.machine_id}
            mac_ids = machine_log.keys 
            bls = machine_ids - mac_ids  
            mer_req = bls.map{|i| [i,[]]}.to_h
            machine_log = machine_log.merge(mer_req)
            full_logs = full_logs.merge(mer_req) ##1##
#	    value1 = full_logs[key]

           machine_log.each do |key, value|
#b#yebug
            value1 = full_logs[key]
            puts value.count
            puts value1.count
#		if value.count == 1 && value1.count == 15025
#            byebug
#	end
            tot_time_res = Machine.new_run_time(value, value1, hour_start_time[0].to_time, (hour_end_time.to_time-1))
 #     	     end 
            run_time = tot_time_res[:run_time]
            stop_time = tot_time_res[:stop_time]
            ideal_time = tot_time_res[:idle_time]
       
            # run_time = Machine.run_time(value)
            # stop_time = Machine.stop_time(value)
            # ideal_time = Machine.ideal_time(value)
#byebug            
            #part_time = Shift.parts_time3(value, value1)
            find_data = data.flatten.select{|i| i[:machine_id] == key }
            final_data = find_data.select{|i| i[:time] >= hour_start_time[0].to_time && i[:time] <= (hour_end_time.to_time-1)}
            
#byebug
            #cycle_st_to_st = @part_time.pluck(:cycle_st_to_st).map{|i| i.to_i}
            cutting_time = final_data.pluck(:cutting_time).map{|i| i.to_i}
            #cycle_stop_to_stop = @part_time.pluck(:cycle_stop_to_stop).map{|i| i.to_i}
#byebug
            cycle_time = final_data.pluck(:cycle_time).flatten
		a = []
	        cycle_time.each do |i|
        	a << eval(i)
	        end


            job_description = value.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
            duration = hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i

            time_diff = duration - (run_time+stop_time+ideal_time)
            utilization =(run_time*100)/duration if duration.present?
            

	             target = []
		 operator_detail = OperatorAllocation.where(machine_id:key, shifttransaction_id:shift.id,date:date2)

                if operator_detail.present?
			operator_detail.last.operator_allot_details.each do |i|
		#		@operator_id = 
	                        #@
				operator_id = i.operator_id
#				operator_id = operator_detail.last.operator_allot_details.operator_id
 	#		target = 0 
 #                       operator_detail.operator_allot_details.each do |i|
  #                         time = (i.start_time.to_i..i.end_time.to_i).step(3600).each do |hour|
            #    byebug                
   #                          cycle_time = i.operation_management.std_cycle_time.to_i + i.operation_management.load_unload_time.to_i
    #                          t_hr = hour/cycle_time
     #                         target << (i.end_time.to_i - i.start_time.to_i)/cycle_time
      #                       target << t_hr
#				target = 0
                           end
                   #     end
##
                else
                        operator_id = nil
                        target = []
#			target = 0
                end
                     total_target = target.sum

 #    byebug       
            # feed_rate_min = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).min
            feed_rate_max = value.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max
             
          # spindle_speed_min = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            spindle_speed_max = value.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
            
            sp_temp_min = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            sp_temp_max = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

            spindle_load_min = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            spindle_load_max = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

           
            mac_setting_id =  MachineSetting.find_by(machine_id: key).id if MachineSetting.present? rescue nil    
            data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)
             
            axis_loadd = []
            tempp_val = []
            puls_coder = []
            
            if value.present?
              unless value.first.machine.controller_type == 2
                value.last.x_axis.first.each_with_index do |key, index|
#byebug
                  if data_val.include?(key[0].to_s)
                    # key = 0
                    load_value =  value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    temp_value =  value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    puls_value =  value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    
#byebug
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
              end
            end

 #     byebug    
            @alldata << [
               date, 			#data[0]
               hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1], #data[1]
               duration, 		#data[2]
               shift.shift.id, 		#data[3]
               shift.shift_no, 		#data[4]
               operator_id,  		#data[5]
               key,  			#data[6]
               job_description.nil? ? "-" : job_description.split(',').join(" & "), #data[7]
               cutting_time.count, 	#data[8]
               run_time, 		#data[9]
               ideal_time,  		#data[10]
               stop_time,  		#data[11]
               time_diff,  		#data[12]
               value.count,  		#data[13]
               utilization, 		#data[14]
               tenant.to_i, 		#data[15]
               cycle_time, 		#data[16]
               cutting_time,  		#data[17]
               spindle_load_min.to_s+' - '+spindle_load_max.to_s, 	#data[18]
               sp_temp_min.to_s+' - '+sp_temp_max.to_s, 		#data[19]
               axis_loadd,  		#data[20]
               tempp_val, 		#data[21]
               puls_coder,  		#data[22]
               feed_rate_max.to_s, 	#data[23]
               spindle_speed_max.to_s,  #data[24]
               target,#.sum 		#data[25]
	       a  			#data[26]
            ]
           end
        end
      end
    
     if @alldata.present?
      @alldata.each do |data|
#byebug
        if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[26],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
        else
          CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[26],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24])
        end
      end

      end 
  
end



def self.cnc_report_simple_query_hour_vino(tenant, shift_no, date, data)
#byebug
  date = date
  date2 = date.to_date.strftime("%Y-%m-%d %H:%M:%S")
    @alldata = []
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

      machine_ids = Tenant.find(tenant).machines.where(controller_type: 1).pluck(:id)

      #full_log = MachineDailyLog.includes(:machine).where(machines: {tenant_id: tenant, controller_type: 1}).group_by{|x| x.machine_id}
      full_logs = MachineDailyLog.where(machine_id: machine_ids).group_by{|x| x.machine_id} ##1##
byebug
	operator_allocations = OperatorAllocation.where(date: date.to_time.strftime("%Y-%m-%d %H:%M:%S"), shifttransaction_id: shift.id)
    operators = Operator.all.group_by{|i| i[:id]}
#    operator_allot_details  = 
    operation_managements = OperationManagement.all.group_by{|i| i[:id]}

	@id = []

      (start_time.to_i..end_time.to_i).step(3600) do |hour|
#byebug
        (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))

         hour_strt_time = hour_start_time[0]

        unless hour_start_time[0].to_time == hour_end_time.to_time
#byebug
           machine_log = MachineDailyLog.where(created_at: hour_start_time[0].to_time..(hour_end_time.to_time-1), machine_id: machine_ids).group_by{|x| x.machine_id}
            mac_ids = machine_log.keys
            bls = machine_ids - mac_ids
            mer_req = bls.map{|i| [i,[]]}.to_h
            machine_log = machine_log.merge(mer_req)
            full_logs = full_logs.merge(mer_req) ##1##
#           value1 = full_logs[key]

           machine_log.each do |key, value|
#b#yebug
            value1 = full_logs[key]
            puts value.count
            puts value1.count
#               if key == 2
#            byebug
            tot_time_res = Machine.new_run_time(value, value1, hour_start_time[0].to_time, (hour_end_time.to_time-1))
 #           end
            run_time = tot_time_res[:run_time]
            stop_time = tot_time_res[:stop_time]
            ideal_time = tot_time_res[:idle_time]

            # run_time = Machine.run_time(value)
            # stop_time = Machine.stop_time(value)
            # ideal_time = Machine.ideal_time(value)
#byebug
            #part_time = Shift.parts_time3(value, value1)
            find_data = data.flatten.select{|i| i[:machine_id] == key }
            final_data = find_data.select{|i| i[:time] >= hour_start_time[0].to_time && i[:time] <= (hour_end_time.to_time-1)}

#byebug
            #cycle_st_to_st = @part_time.pluck(:cycle_st_to_st).map{|i| i.to_i}
            cutting_time = final_data.pluck(:cutting_time).map{|i| i.to_i}
            #cycle_stop_to_stop = @part_time.pluck(:cycle_stop_to_stop).map{|i| i.to_i}
            cycle_time = final_data.pluck(:cycle_time).flatten
                a = []
                cycle_time.each do |i|
                a << eval(i)
                end


            job_description = value.pluck(:job_id).uniq.reject{|i| i.nil? || i == ""}
            duration = hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i

            time_diff = duration - (run_time+stop_time+ideal_time)
            utilization =(run_time*100)/duration if duration.present?
#	    hour_start_time = hour_start_time[0].to_s
	    shiftnumber = shift.id
#	    target_data = Delivery.target_calculation1(hour_start_time, hour_end_time, shift_id, key, date2)
	    #target_data = Delivery.target_calculation1(shiftnumber, key, date2, hour_start_time[0].to_time, hour_end_time.to_time)
byebug
			 total_target = []
#             @operator_detail = OperatorAllocation.where(machine_id:key, shifttransaction_id:shift.id,date:date2)
	      @operator_detail = operator_allocations.select{|x| x.machine_id == key}
             if @operator_detail.present?  
                         @operator_detail.last.operator_allot_details.each do |single_operator|
byebug
                                operation_start_time = single_operator.start_time.to_time.localtime
                                operation_end_time = single_operator.end_time.to_time.localtime

                                        (operation_start_time.to_i..operation_end_time.to_i).step(3600) do |hour|   #8.30 to 9.3i0
byebug
                                        (hour.to_i+3600 <= operation_end_time.to_i) ? (target_hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M:%S"),target_hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M:%S")) : (target_hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M:%S"),target_hour_end_time=Time.at(operation_end_time).strftime("%Y-%m-%d %H:%M:%S"))
                                        #hr_strt_time = Time.parse(hour_start_time[0]).seconds_since_midnight
                                        #hr_end_time = Time.parse(hour_end_time).seconds_since_midnight
#                                       time = (hr_end_time - hr_strt_time).to_i
#					if (hour_start_time[0].to_time.localtime.. hour_end_time.to_time.localtime).include?(operation_start_time || operation_end_time)
                                        unless target_hour_start_time[0].to_time == target_hour_end_time.to_time
byebug
                                         operator_id = single_operator.operator_id

                                         operation_management_id = single_operator.operation_management_id

                                         total_cycle_time = single_operator.operation_management.std_cycle_time.to_i + single_operator.operation_management.load_unload_time.to_i
                                         target_value = (target_hour_end_time.to_time.to_i - target_hour_start_time[0].to_time.to_i)/total_cycle_time

                                         total_target << {start_time: target_hour_start_time[0].to_time, end_time: target_hour_end_time.to_time, operator_id: operator_id, operation_management_id: operation_management_id, target_value: target_value}
						@id << total_target
byebug
					   end
                                        end
					end
                                 else
                                       operator_id = nil
                                        total_target = []
                                 end

				 	
#                                 end
  #             else
   #                    operator_id = nil
    #                   total_target = []
     #        end



            # feed_rate_min = machine_log1.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).min
            feed_rate_max = value.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000 || i == 0 }.map(&:to_i).max

          # spindle_speed_min = machine_log1.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            spindle_speed_max = value.pluck(:cutting_speed).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

            sp_temp_min = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            sp_temp_max = value.pluck(:z_axis).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max

            spindle_load_min = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min
            spindle_load_max = value.pluck(:spindle_load).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max
            mac_setting_id =  MachineSetting.find_by(machine_id: key).id if MachineSetting.present? rescue nil
            data_val = MachineSettingList.where(machine_setting_id: mac_setting_id, is_active: true).pluck(:setting_name)

            axis_loadd = []
            tempp_val = []
            puls_coder = []
byebug
            if value.present?
              unless value.first.machine.controller_type == 2
                value.last.x_axis.first.each_with_index do |key, index|
#byebug
                  if data_val.include?(key[0].to_s)
                    # key = 0
                    load_value =  value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:x_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    temp_value =  value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:y_axis).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s
                    puls_value =  value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).min.to_s+' - '+value.pluck(:cycle_time_minutes).sum.pluck(key[0]).reject{|i| i == "" || i.nil? || i == 0 }.map(&:to_i).max.to_s

#byebug
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
              end
	    end

 #     byebug
            @alldata << [
               date,  #data[0]
               hour_start_time[0].split(" ")[1]+' - '+hour_end_time.split(" ")[1], #data[1]
               duration, #data[2]
               shift.shift.id, #data[3]
               shift.shift_no, #data[4]
               operator_id,  #data[5]
               key,  #data[6]
               job_description.nil? ? "-" : job_description.split(',').join(" & "), #data[7]
               cutting_time.count, #data[8]
               run_time, #data[9]
               ideal_time,  #data[10]
               stop_time,  #data[11]
               time_diff,  #data[12]
               value.count,  #data[13]
               utilization, #data[14]
               tenant.to_i, #data[15]
               cycle_time, #data[16]
               cutting_time,  #data[17]
               spindle_load_min.to_s+' - '+spindle_load_max.to_s, #data[18]
               sp_temp_min.to_s+' - '+sp_temp_max.to_s, #data[19]
               axis_loadd,  #data[20]
               tempp_val, #data[21]
               puls_coder,  #data[22]
               feed_rate_max.to_s, #data[23]
               spindle_speed_max.to_s, #data[24]
               total_target,#.sum #data[25]
               a  #data[26]
            ]
           end
        end
      end

     if @alldata.present?
      @alldata.each do |data|
#byebug
        if CncHourReport.where(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).present?
          CncHourReport.find_by(date:data[0],shift_no: data[4], time: data[1], machine_id:data[6], tenant_id:data[15]).update(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[26],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24], parts_data: data[25])
        else
          CncHourReport.create!(date:data[0], time: data[1], hour: data[2], shift_id: data[3], shift_no: data[4], operator_id: data[5], machine_id: data[6], job_description: data[7], parts_produced: data[8], run_time: data[9], ideal_time: data[10], stop_time: data[11], time_diff: data[12], log_count: data[13], utilization: data[14],  tenant_id: data[15], all_cycle_time: data[26],cutting_time: data[17],spindle_load: data[18],spindle_m_temp: data[19],servo_load: data[20], servo_m_temp: data[21], puls_code: data[22],feed_rate:data[23], spendle_speed:data[24], parts_data: data[25])
        end
      end

      end
end

end
