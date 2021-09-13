class Dashboard < ApplicationRecord
 include MachineHelper

	def self.live_status(params,machines,shift)
#byebug
		data = []
		date = Date.today.to_s

		case
    when shift["day"] == 1 && shift["end_day"] == 1
      start_time = (date+" "+shift["shift_start_time"]).to_time
      end_time = (date+" "+shift["shift_end_time"]).to_time
    when shift["day"] == 1 && shift["end_day"] == 2
      if Time.now.strftime("%p") == "AM"
        start_time = (date+" "+shift["shift_start_time"]).to_time-1.day
        end_time = (date+" "+shift["shift_end_time"]).to_time
      else
        start_time = (date+" "+shift["shift_start_time"]).to_time
        end_time = (date+" "+shift["shift_end_time"]).to_time+1.day
      end
    else
     start_time = (date+" "+shift["shift_start_time"]).to_time
      end_time = (date+" "+shift["shift_end_time"]).to_time
    end

		mac_id_list = machines.map{|i| i["id"]}
		logs = MachineDailyLog.where(created_at: start_time..end_time, machine_id: mac_id_list)
		machines.each do |mac|
			mac_log = logs.select{|i| i.machine_id == mac["id"]}
#byebug			
			macro = []
#			macro = MacroSignalOpened.where(machine_id: mac ["id"]).last.value if MacroSignalOpened.present? rescue nil
			macro = MacroSignalOpened.where(machine_id: mac ["id"]).order("update_date DESC").first.value if MacroSignalOpened.present? rescue nil
			reason = HmiReason.where(spec_id: macro).last.name if HmiReason.present? rescue nil
			data << {
      :unit => mac["unit"],
      :mac_name => mac ["machine_name"],
      :machine_id=>mac ["id"],
      :machine_status=>mac_log.last.present? ? (Time.now - mac_log.last.created_at) > 18000 ? nil : mac_log.last.machine_status : nil,
#      :machine_status=>mac_log.last.present? ? (Time.now - mac_log.last.created_at) > 3600 ? nil : mac_log.last.machine_status : nil,
      :shift_no=>shift["shift_no"],
      :start_time=>start_time,
      :macro=> mac_log.last.present? && mac_log.last.machine_status <= 2 ? reason.present? ? reason  : "REASON NOT ENTERED" : "No idle"
      }
 	 	end 
 	 	return  data
  end

	def self.single_machine_live_status(params,machine,shift)
		date = Date.today.to_s
		case
    when shift["day"] == 1 && shift["end_day"] == 1
      start_time = (date+" "+shift["shift_start_time"]).to_time
      end_time = (date+" "+shift["shift_end_time"]).to_time
    when shift["day"] == 1 && shift["end_day"] == 2
      if Time.now.strftime("%p") == "AM"
        start_time = (date+" "+shift["shift_start_time"]).to_time-1.day
        end_time = (date+" "+shift["shift_end_time"]).to_time
      else
        start_time = (date+" "+shift["shift_start_time"]).to_time
        end_time = (date+" "+shift["shift_end_time"]).to_time+1.day
      end
    else
      start_time = (date+" "+shift["shift_start_time"]).to_time
      end_time = (date+" "+shift["shift_end_time"]).to_time
    end

    axis_return = []
    tem_return = []
    puls_code = []

		shift_no = shift["shift_no"]
		mac_id = machine["id"]
		full_logs = MachineDailyLog.where(machine_id: mac_id)
		logs = full_logs.select{|a| a.created_at > start_time && a.created_at < end_time }
    parts = Part.where(date: date, shift_no: shift_no,machine_id:mac_id)
    run_part = parts.select{|aa|aa.cycle_start!=nil}
    alarm = Alarm.where(machine_id: mac_id).present? ? Alarm.where(machine_id: mac_id).last.alarm_message : "No Alarm"

    data_val = MachineSettingList.where(machine_setting_id: MachineSetting.find_by(machine_id: mac_id).id,is_active: true).pluck(:setting_name)  

		times = Machine.new_run_time(logs, full_logs, start_time, Time.now.localtime)
		duration = (end_time.to_i - start_time.to_i).to_i
    run = times[:run_time]
    idle = times[:idle_time]
    stop = times[:stop_time]
    utilization = (run*100)/duration

    if run_part.present?
    	cycle_time = run_part.last.cycle_time.to_i
    	cutting_time = run_part.last.cutting_time.to_i
    	job_wise_parts = run_part.group_by { |name| name[:program_number] }.map{|k,v| [k,v.count]}.to_h
    else
    	cycle_time = 0
    	cutting_time = 0
    	job_wise_parts = {}
    end

    if logs.present? && logs.pluck(:machine_status).include?(3)
    	total_run_time = logs.select{|a| a.machine_status == 3}.last.total_run_time * 100 + logs.select{|a| a.machine_status == 3}.last.total_run_second/1000
    	spindle_load = logs.last.spindle_load
    	feed_rate = logs.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000  }.last
      spindle_speed = logs.pluck(:cutting_speed).reject{|i| i == "" || i.nil?  }.last

      logs.last.x_axis.first.each_with_index do |key, index|
        if data_val.include?(key[0].to_s)
          axis_return << key
        end
      end

      logs.last.y_axis.first.each_with_index do |key, index|
        if data_val.include?(key[0].to_s)
          tem_return << key
        end
      end

      logs.last.cycle_time_minutes.first.each_with_index do |key, index|
        if data_val.include?(key[0].to_s)
          puls_code << key
        end
      end


	    @val = axis_return.to_h
	    @val2 = tem_return.to_h
	    @val3 = puls_code.to_h
	    sp_temp = logs.last.z_axis.to_i


    else
    	total_run_time = 0
    	spindle_load = 0
    	feed_rate = logs.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000  }.present? ? logs.pluck(:feed_rate).reject{|i| i == "" || i.nil? || i > 5000  }.last : 0
      spindle_speed = logs.pluck(:cutting_speed).reject{|i| i == "" || i.nil?  }.present? ? logs.pluck(:cutting_speed).reject{|i| i == "" || i.nil?  }.last : 0  
      if logs.present?
	      logs.last.x_axis.first.each_with_index do |key, index|
	      	if data_val.include?(key[0].to_s)
	          axis_return << [key[0], 0]
	        end
	      end
	      
	      logs.last.y_axis.first.each_with_index do |key, index|
	        if data_val.include?(key[0].to_s)
	          tem_return << [key[0], 0]
	        end
	      end
	 
	      logs.last.cycle_time_minutes.first.each_with_index do |key, index|
	        if data_val.include?(key[0].to_s)
	          puls_code << [key[0], 0]
	        end
	      end
      end

      @val = axis_return.to_h
	    @val2 = tem_return.to_h
	    @val3 = puls_code.to_h
      sp_temp = 0
    end
    alloc_data = OperatorAllocation.where(shifttransaction_id: shift["id"], machine_id: machine["id"], date: date)
    if alloc_data.present?
     op_detail = alloc_data.last.operator_allot_details
     if op_detail.present?
      op_name = op_detail.last.operator.operator_name
     else
      op_name = "Operator Not Present"
     end
    else
     op_name = "Operator Not Present"
    end
#     byebug 
	if axis_return.present?
     axis_hash = axis_return.to_h
     axis_string = axis_hash.stringify_keys
     axis_keys = axis_string.keys
     axis_values = axis_string.values
	end
		  data = {
#      :last_update=>full_logs.last.present? ? full_logs.order(:id).last.created_at.in_time_zone("Chennai").strftime("%Y-%m-%d %I:%M:%S %p") : 0,
      :last_update=>full_logs.last.present? ? full_logs.order(:id).last.created_at.localtime.strftime("%d-%m-%Y %I:%M:%S %p") : 0,
#      :last_update=>full_logs.last.present? ? full_logs.order(:id).last.(Time.at(created_at.to_i).utc.strftime(" %H:%M:%S %p"))
      :shift_no => shift_no,
      :shift_time => shift["shift_start_time"]+ ' - ' +shift["shift_end_time"],
      :machine_name => machine["machine_name"],
      :machine_id => mac_id,
      :utilization => utilization != nil ? utilization : 0,
      :run_time => run != nil ? Time.at(run).utc.strftime("%H:%M:%S") : "00:00:00",
      :idle_time => idle != nil ?  idle > 0 ? Time.at(idle).utc.strftime("%H:%M:%S") : "00:00:00" : "00:00:00",
      :stop_time => stop != nil ? stop > 0 ? Time.at(stop).utc.strftime("%H:%M:%S") : "00:00:00" : "00:00:00",
      :cycle_time => cycle_time.present? ? Time.at(cycle_time).utc.strftime("%H:%M:%S") : "00:00:00",
      :cutting_time => cutting_time.present? ? Time.at(cutting_time).utc.strftime("%H:%M:%S") : "00:00:00",
 #     :machine_status => logs.last.present? ? (Time.now - logs.last.created_at) > 600 ? nil : logs.last.machine_status : nil,
      :machine_status => logs.last.present? ? (Time.now - logs.last.created_at) > 18000 ? nil : logs.last.machine_status : nil,
      :machine_disply => logs.present? ? logs.last.parts_count : 0,
      :parts_count => run_part.present? ? run_part.count : 0,
      :job_name => logs.select{|a| a.job_id != "" && a.programe_number != nil}.last.present? ? ""+logs.select{|a| a.job_id != "" && a.programe_number != nil}.last.programe_number+"-"+logs.select{|a| a.job_id != "" && a.programe_number != nil}.last.job_id : nil,
      :total_run_time => total_run_time != nil ? total_run_time > 0 ? Time.at(total_run_time).utc.strftime("%H:%M:%S") : "00:00:00" : "00:00:00",
      :alarm => alarm,
	    :job_wise_parts => job_wise_parts.present? ? job_wise_parts : 0,
	    :feed_rate => feed_rate.present? ? feed_rate : 0,
	    :spindle_load => spindle_load.present? ?  spindle_load : 0,
	    :spindle_speed => spindle_speed.present? ? spindle_speed : 0,
	    :sp_temp => sp_temp,
	    :axis_load => axis_return.present? ? axis_return.to_h : [],
#	    :axis_load_key => axis_return.present? ? a
	    :axis_tem => tem_return.present? ? tem_return.to_h : [],
	    :puls_code => puls_code.present? ? puls_code.to_h : [],
	    :axis_tem_count => @val2.present? ? @val2.count : 0,
	    :start_time=>start_time,
            :operator_allocation=>op_name.present? ? op_name : "Name not Entered",
	    :axis_keys=>axis_keys.present? ? axis_keys : [],
	    :axis_values => axis_values.present? ? axis_values : []
    }
	end

 	
end
