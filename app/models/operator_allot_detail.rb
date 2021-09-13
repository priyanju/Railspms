class OperatorAllotDetail < ApplicationRecord
  belongs_to :operation_management
  belongs_to :operator_allocation, required: false
  belongs_to :tenant
  belongs_to :operator

  
#  accepts_nested_attributes_for :operator_allocations
		

# def self.target_calculation(key, shift.id, date)
#	  date = date
#	  date2 = date.to_date.strftime("%Y-%m-%d %H:%M:%S")
#
 #     	  operator_detail = OperatorAllocation.where(machine_id:key, shifttransaction_id:shift.id,date:date2)
#	     if operator_detail.present?
#			 operator_detail.last.operator_allot_details.each do |single_operator|
#			
#				operation_start_time = single_operator.start_time
#				operation_end_time = single_operator.end_time
#	                         (i.start_time.to_i..i.end_time.to_i).step(3600).each do |hour|
#					
#					operator_id = single_operator.operator_allot_details.operator_id
#
 #                    	        cycle_time = i.operation_management.std_cycle_time.to_i + i.operation_management.load_unload_time.to_i
  #                              t_hr = hour/cycle_time
 #                               target << (i.end_time.to_i - i.start_time.to_i)/cycle_time
   #                             target << t_hr
    #                       	end
     #                   	end
#	
 #               else
 #                       operator_id = nil
  #                      target = []
#	  end
 #                    total_target = target.sum
#
 #end
end
