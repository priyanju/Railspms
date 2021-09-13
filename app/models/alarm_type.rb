class AlarmType < ApplicationRecord
def self.file_sync(tenant, shift, date)
	require 'csv'
    tenant = Tenant.find(tenant)
   # tenants = Tenant.where(isactive: true)#.pluck(:tenant_name)
   # tenants.each do |tenant|
	    #date = Date.today.strftime("%Y-%m-%d") # "2019-12-25"
	    #date = "2020-08-24"

	    shift = tenant.shift.shifttransactions.find_by_shift_no(shift)
	     
	      case
	      when shift.day == 1 && shift.end_day == 1   
	        start_time = (date+" "+shift.shift_start_time).to_time
	        end_time = (date+" "+shift.shift_end_time).to_time  
	      when shift.day == 1 && shift.end_day == 2
	        start_time = (date+" "+shift.shift_start_time).to_time
	        end_time = (date+" "+shift.shift_end_time).to_time+1.day    
	      when shift.day == 2 && shift.end_day == 2
	        start_time = (date+" "+shift.shift_start_time).to_time+1.day
	        end_time = (date+" "+shift.shift_end_time).to_time+1.day     
	      end
               

               path1 = "/home/ubuntu/machine_log_files/#{date}"
               path = "/home/ubuntu/machine_log_files/#{date}/#{tenant.tenant_name}_#{shift.shift_no}.csv"
	   #   path1 = "/home/altius/YANTRA/machine_log_files/#{date}"
       # path = "/home/altius/YANTRA/machine_log_files/#{date}/#{tenant.tenant_name}_#{shift.shift_no}.csv"
	      a = FileUtils.mkdir_p(path1) unless File.exist?(path1)
	      machines = tenant.machines.pluck(:id)
	      logs = MachineLog.where("created_at >=? AND created_at <?",start_time,end_time).where(machine_id: machines).order(:id)
        message = "#{tenant.tenant_name}-#{shift.shift_no}-#{logs.count}/SYNC TO S3"
	      CSV.open(path, "wb") do |csv|
	        csv << ["id", "parts_count", "machine_status", "job_id", "total_run_time", "total_cutting_time", "run_time", "feed_rate", "cutting_speed", "axis_load", "axis_name", "spindle_speed", "spindle_load", "total_run_second", "programe_number", "programe_description", "run_second", "machine_id", "created_at", "updated_at", "machine_time", "x_puls", "y_puls", "z_puls", "a_puls", "b_puls", "machine_total_time", "cycle_time_per_part", "total_cutting_second", "x_load", "y_load", "z_load", "a_load", "z_load", "x_temp", "y_temp", "z_temp", "a_temp", "b_temp", "z_axis", "reason"]
	         
		      logs.each do |detail|
	          if detail.x_axis.present?
	            csv << [detail.id, detail.parts_count, detail.machine_status, detail.job_id, detail.total_run_time, detail.total_cutting_time, detail.run_time, detail.feed_rate, detail.cutting_speed, detail.axis_load, detail.axis_name, detail.spindle_speed, detail.spindle_load, detail.total_run_second, detail.programe_number, detail.programe_description, detail.run_second, detail.machine_id, detail.created_at, detail.updated_at, detail.machine_time, detail.cycle_time_minutes.first[:x_axis], detail.cycle_time_minutes.first[:y_axis], detail.cycle_time_minutes.first[:z_axis], detail.cycle_time_minutes.first[:a_axis], detail.cycle_time_minutes.first[:b_axis], detail.machine_total_time, detail.cycle_time_per_part, detail.total_cutting_second, detail.x_axis.first[:x_axis], detail.x_axis.first[:y_axis], detail.x_axis.first[:z_axis], detail.x_axis.first[:a_axis], detail.x_axis.first[:b_axis], detail.y_axis.first[:x_axis], detail.y_axis.first[:y_axis], detail.y_axis.first[:z_axis], detail.y_axis.first[:a_axis], detail.y_axis.first[:b_axis], detail.z_axis, detail.reason]
	          else
	            csv << [detail.id, detail.parts_count, detail.machine_status, detail.job_id, detail.total_run_time, detail.total_cutting_time, detail.run_time, detail.feed_rate, detail.cutting_speed, detail.axis_load, detail.axis_name, detail.spindle_speed, detail.spindle_load, detail.total_run_second, detail.programe_number, detail.programe_description, detail.run_second, detail.machine_id, detail.created_at, detail.updated_at, detail.machine_time, nil, nil, nil, nil, nil, detail.machine_total_time, detail.cycle_time_per_part, detail.total_cutting_second, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, detail.z_axis, detail.reason]
	          end
		      end
        end
	AlarmType.delay(run_at: end_time + 48.hours, tenant: tenant.id, shift: shift.shift_no, date: date, method: "remove_data").remove_data(tenant.id, shift.shift_no, date)
	end

def self.remove_data(tenant, shift, date)
   tenant = Tenant.find(tenant)
date = date.to_time.strftime("%Y-%m-%d")
            shift = tenant.shift.shifttransactions.find_by_shift_no(shift)
              case
              when shift.day == 1 && shift.end_day == 1
                start_time = (date+" "+shift.shift_start_time).to_time
                end_time = (date+" "+shift.shift_end_time).to_time
              when shift.day == 1 && shift.end_day == 2
                start_time = (date+" "+shift.shift_start_time).to_time
                end_time = (date+" "+shift.shift_end_time).to_time+1.day
              when shift.day == 2 && shift.end_day == 2
                start_time = (date+" "+shift.shift_start_time).to_time+1.day
                end_time = (date+" "+shift.shift_end_time).to_time+1.day
              end
  machines = tenant.machines.pluck(:id)
 path = "/home/ubuntu/machine_log_files/#{date}/#{tenant.tenant_name}_#{shift.shift_no}.csv"
logs = MachineLog.where("created_at >=? AND created_at <?",start_time,end_time).where(machine_id: machines).order(:id)
 require 'csv'
text= CSV.read(path)
if (text.count - 1) == logs.count
puts logs.count
puts "=================***================="
 logs.delete_all
else
# logs.delete_all 
puts "=================***================="
puts "NOTHING DELETE"
puts "=================***================="
end


end
end
