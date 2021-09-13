class Delivery < ApplicationRecord
belongs_to :tenant 
belongs_to :cncjob
belongs_to :deliverytype


   def self.target_calculation(tenant, key, shift_no, date)
   byebug        
  date = date
          date2 = date.to_date.strftime("%Y-%m-%d %H:%M:%S")
	  tenant = Tenant.find(tenant)
	  shifts = Shifttransaction.includes(:shift).where(shifts: {tenant_id: tenant})
     	  shift = shifts.find_by_shift_no(shift_no)

	     case
      		when shift.day == 1 && shift.end_day == 1
	        @start_time = (date+" "+shift.shift_start_time).to_time
        	@end_time = (date+" "+shift.shift_end_time).to_time
	        when shift.day == 1 && shift.end_day == 2
        	@start_time = (date+" "+shift.shift_start_time).to_time
        	@end_time = (date+" "+shift.shift_end_time).to_time+1.day
      	     else
        	@start_time = (date+" "+shift.shift_start_time).to_time+1.day
        	@end_time = (date+" "+shift.shift_end_time).to_time+1.day
      	     end
		total_target = []
		@id = []
             @operator_detail = OperatorAllocation.where(machine_id:key, shifttransaction_id:shift.id,date:date2)
             if @operator_detail.present?
                         @operator_detail.last.operator_allot_details.each do |single_operator|
byebug
                                operation_start_time = single_operator.start_time.to_time.localtime
                                operation_end_time = single_operator.end_time.to_time.localtime
	
				if (@start_time..@end_time).include?(operation_start_time..operation_end_time)
					(operation_start_time.to_i..operation_end_time.to_i).step(3600) do |hour|   #8.30 to 9.3i0
byebug					
					(hour.to_i+3600 <= operation_end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M:%S"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M:%S")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M:%S"),hour_end_time=Time.at(operation_end_time).strftime("%Y-%m-%d %H:%M:%S"))			
					#hr_strt_time = Time.parse(hour_start_time[0]).seconds_since_midnight
					#hr_end_time = Time.parse(hour_end_time).seconds_since_midnight
#					time = (hr_end_time - hr_strt_time).to_i
										
	
					unless hour_start_time[0].to_time == hour_end_time.to_time
byebug					
  					 operator_id = single_operator.operator_id

 					 operation_management_id = single_operator.operation_management_id 

					 total_cycle_time = single_operator.operation_management.std_cycle_time.to_i + single_operator.operation_management.load_unload_time.to_i
		                         target_value = (hour_end_time.to_time.to_i - hour_start_time[0].to_time.to_i)/total_cycle_time

		                         total_target << {start_time: hour_start_time[0].to_time, end_time: hour_end_time.to_time, operator_id: operator_id, operation_management_id: operation_management_id, target_value: target_value}
	
					 end
					end	
				 else
					operator_id = nil
		                        total_target = []
				 end
				
				 end
               else
                       operator_id = nil
                       total_target = []
             end   
		       return total_target
   end


   def self.target_calculation1(shiftnumber, key, date2, hour_strt_time, hour_end_time)
byebug
	 @start_time = hour_strt_time
	 @end_time = hour_end_time
	 total_target = []
         @id = []
         @operator_detail = OperatorAllocation.where(machine_id:key, shifttransaction_id:shiftnumber,date:date2)
         if @operator_detail.present?
            @operator_detail.last.operator_allot_details.each do |single_operator|
byebug	
             operation_start_time = single_operator.start_time.to_time.localtime#.strftime("%d-%m-%Y %I:%M")
             operation_end_time = single_operator.end_time.to_time.localtime#.strftime("%d-%m-%Y %I:%M")
             if (@start_time..@end_time).include?(operation_start_time || operation_end_time)
                (operation_start_time.to_i..operation_end_time.to_i).step(3600) do |hour|   #8.30 to 9.3i0
byebug
                   (hour.to_i+3600 <= operation_end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(operation_end_time).strftime("%Y-%m-%d %H:%M"))	
#			if @start_time == hour_start_time && @end_time == hour_end_time
                        unless @end_time == hour_end_time.to_time
				 if @start_time == hour_start_time && @end_time == hour_end_time
	                         operator_id = single_operator.operator_id
				 operation_management_id = single_operator.operation_management_id

                	         total_cycle_time = single_operator.operation_management.std_cycle_time.to_i + single_operator.operation_management.load_unload_time.to_i
                        	 target_value = (@end_time.to_time.to_i - @start_time.to_time.to_i)/total_cycle_time
                         	 total_target << {start_time: hour_start_time[0].to_time, end_time: hour_end_time.to_time, operator_id: operator_id, operation_management_id: operation_management_id, target_value: target_value}
				  end
                                                end
                                        end
                                 else
byebug
                                        operator_id = nil
                                        total_target = []
                                 end

                                 end
              else
                       operator_id = nil
                       total_target = []
         end
#                        return total_target
   end

  
 def self.target_calculation123(tenant, key, shift_no, date)
  date = date
  date2 = date.to_date.strftime("%Y-%m-%d %H:%M:%S")
  tenant = Tenant.find(tenant)
  shifts = Shifttransaction.includes(:shift).where(shifts: {tenant_id: tenant})
  shift = shifts.find_by_shift_no(shift_no)
    case
     when shift.day == 1 && shift.end_day == 1
      @start_time = (date+" "+shift.shift_start_time).to_time
      @end_time = (date+" "+shift.shift_end_time).to_time
     when shift.day == 1 && shift.end_day == 2
      @start_time = (date+" "+shift.shift_start_time).to_time
      @end_time = (date+" "+shift.shift_end_time).to_time+1.day
     else
      @start_time = (date+" "+shift.shift_start_time).to_time+1.day
      @end_time = (date+" "+shift.shift_end_time).to_time+1.day
     end
      total_target = []
      @id = []
      @operator_detail = OperatorAllocation.where(machine_id:key, shifttransaction_id:shift.id,date:date2)
      if @operator_detail.present?
         @operator_detail.last.operator_allot_details.each do |single_operator|
          operation_start_time = single_operator.start_time.to_time.localtime
          operation_end_time = single_operator.end_time.to_time.localtime
#byebug
           (operation_start_time.to_i..operation_end_time.to_i).step(3600) do |hour|   #8.30 to 9.3i0
#byebug
	     hour_start_time = Time.at(hour).strftime("%Y-%m-%d %H:%M:%S") 
	     hour_end_time = Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M:%S")
#byebug
	      if (hour_start_time..hour_end_time).include?(operation_end_time.strftime("%Y-%m-%d %H:%M:%S"))
		@hour_new_time = operation_end_time.strftime("%Y-%m-%d %H:%M:%S")
                unless hour_start_time.to_time == @hour_new_time.to_time
byebug
                 operator_id = single_operator.operator_id
                 operation_management_id = single_operator.operation_management_id
                 total_cycle_time = single_operator.operation_management.std_cycle_time.to_i + single_operator.operation_management.load_unload_time.to_i
		  if @hour_new_time != hour_start_time
		     target_value = (@hour_new_time.to_time.to_i - hour_start_time.to_time.to_i)/total_cycle_time
		  else
                     target_value = (hour_end_time.to_time.to_i - hour_start_time.to_time.to_i)/total_cycle_time
	          end
                   total_target << {start_time: hour_start_time.to_time, end_time: @hour_new_time.to_time, operator_id: operator_id, operation_management_id: operation_management_id, target_value: target_value}
                end
byebug
		        hour_start_time = @hour_new_time
			@hour_new_time = hour_end_time
		else			
 		unless hour_start_time.to_time == hour_end_time.to_time
byebug
                  operator_id = single_operator.operator_id
                  operation_management_id = single_operator.operation_management_id
                  total_cycle_time = single_operator.operation_management.std_cycle_time.to_i + single_operator.operation_management.load_unload_time.to_i
                  target_value = (hour_end_time.to_time.to_i - hour_start_time.to_time.to_i)/total_cycle_time
                  total_target << {start_time: hour_start_time.to_time, end_time: hour_end_time.to_time, operator_id: operator_id, operation_management_id: operation_management_id, target_value: target_value}
	        end
					 end
                                        end
#                                 else
#                                        operator_id = nil
 #                                       total_target = []
                                 end
#
 #                                end
               else
                       operator_id = nil
                       total_target = []
             end
                       return total_target
   end


	
end














