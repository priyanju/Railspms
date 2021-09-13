class CncHourReportSerializer < ActiveModel::Serializer
  attributes :id, :date, :shift_no, :time, :operator_id, :operator_name, :machine_name, :machine_type, :job_description, :parts_produced, :actual_running, :idle_time, :total_downtime, :utilization, :shift_id, :actual_working_hours, :loading_and_unloading_time,:spendle_speed, :puls_code,:cutting_time,:feed_rate,:spindle_load,:servo_m_temp,:servo_load,:spindle_m_temp, :cycle_time, :program_number, :servo_m_temp1, :puls_code, :servo_load3, :puls_code1, :ser_load_key, :ser_load_value

def machine_name
  object.machine.machine_name
end

def operator_id
    if object.operator_id == nil
	 "Not Assigned" 
    else
      object.operator.operator_spec_id
    end
end
def machine_type
	object.machine.machine_type
end
def operator_name
    if object.operator_id == nil
	 "Not Assigned" 
    else
	object.operator.operator_name
    end
end

def date
  object.date.strftime("%d-%m-%Y")
end

def actual_running
	#object.run_time.to_i/60
    if object.run_time.to_i > object.ideal_time.to_i && object.run_time.to_i > object.stop_time.to_i
      Time.at(object.run_time.to_i + object.time_diff.to_i).utc.strftime("%H:%M:%S")
    else
	  Time.at(object.run_time.to_i).utc.strftime("%H:%M:%S")
    end
end

def idle_time
	#object.ideal_time.to_i/60
	#Time.at(object.ideal_time.to_i).utc.strftime("%H:%M:%S")

    if object.ideal_time.to_i >= object.run_time.to_i && object.ideal_time.to_i >= object.stop_time.to_i
      Time.at(object.ideal_time.to_i + object.time_diff.to_i).utc.strftime("%H:%M:%S")
    else
	  Time.at(object.ideal_time.to_i).utc.strftime("%H:%M:%S")
    end
end

def total_downtime
	#object.stop_time.to_i/60
	#Time.at(object.stop_time.to_i).utc.strftime("%H:%M:%S")
    if object.stop_time.to_i > object.run_time.to_i && object.stop_time.to_i >  object.ideal_time.to_i
      Time.at(object.stop_time.to_i + object.time_diff.to_i).utc.strftime("%H:%M:%S")
    else
	  Time.at(object.stop_time.to_i).utc.strftime("%H:%M:%S")
    end
end
def program_number1
	if object.all_cycle_time.present?
#byebug
#	object.all_cycle_time.pluck[:program_number].uniq.reject{|i| i == "0" || i == ""}.split(",").join(" | ")
	a = []
	object.all_cycle_time.each do |c|
#byebug
	  a << eval(c)[0][:program_number]
	  
	end
	 a.uniq.reject{|i| i == "0" || i == ""}.split(",").join(" | ")
    else
    	"-"
    end
end

def program_number
        if object.all_cycle_time.present?
          object.all_cycle_time.pluck(:program_number).uniq.reject{|i| i == "0" || i == ""}.split(",").join(" | ")
    else
        "-"
    end
end

def cycle_time
	#byebug
	if object.all_cycle_time.present?
		#cycle = object.all_cycle_time.pluck(:cycle_time)
		#avg_cycl = cycle.inject(0.0) { |sum, el| sum + el } / cycle.size
		#Time.at(avg_cycl).utc.strftime("%H:%M:%S")
	#object.all_cycle_time.last[:cycle_time]
#byebug
#	  cycle_time = object.all_cycle_time.last
#	  time = eval(cycle_time)[0][:cycle_time]
 #         Time.at(time).utc.strftime("%H:%M:%S")
	 time = object.all_cycle_time.last[:cycle_time]
       Time.at(time).utc.strftime("%H:%M:%S")
        else
    	  "-"
        end
end

def actual_working_hours
	#Time.at(object.hour.to_i).strftime("%H:%M:%S")
	#/60
	#object.hour.to_i/60
	Time.at(object.hour.to_i).utc.strftime("%H:%M:%S")
end

def loading_and_unloading_time
	#object.time_diff.to_i/60
	Time.at(object.time_diff.to_i).utc.strftime("%H:%M:%S")
end

def utilization

   if object.run_time.to_i > object.ideal_time.to_i && object.run_time.to_i > object.stop_time.to_i
      run_time = object.run_time.to_i + object.time_diff.to_i
    else
	  run_time = object.run_time.to_i
    end	
   
     uti = (((run_time*100)/object.hour.to_i).to_f).round
     
end



 def cutting_time
	if object.cutting_time == []
	   "-"	
	else
	   time1 = object.cutting_time.last
	   Time.at(time1.to_i).utc.strftime("%H:%M:%S")  
	end
end


def servo_load3
	if object.servo_load == []
         "-"
        else
	 servo_load =  object.servo_load
	 servo_load = servo_load.inject(&:merge)
	 servo_load = servo_load.map{|k,v| "#{k}:#{v}"}.join(',')
	end
end
	
def servo_m_temp1
	if object.servo_m_temp == []
         "-"
        else
         servo_m_temp =  object.servo_m_temp
	 servo_m_temp =  servo_m_temp.inject(&:merge)
         servo_m_temp = servo_m_temp.map{|k,v| "#{k}:#{v}"}.join(',')
        end
end

def puls_code1
	if object.puls_code == []
         "-"
        else
         puls_code = object.puls_code
	 puls_code = puls_code.inject(&:merge)
	 puls_code = puls_code.map{|k,v| "#{k}:#{v}"}.join(',')
        end
end

def ser_load_key
	if object.servo_load == []
	"-"
	else
	 sl_load = object.servo_load
	 sl_load = sl_load.map {|x| x.keys}  
	 sl_load = sl_load.flatten
	end
end

def ser_load_value
	if object.servo_load == []
        "-"
        else
         sl_load = object.servo_load
	 sl_load = sl_load.map {|x| x.values}
	 sl_load = sl_load.flatten
	end
end
end
