class MacroSignalOpened < ApplicationRecord
  belongs_to :machine
  def self.idle_reason_report(tenant, shift_no, date)
#byebug
    date = date
    date2 = date.to_date.strftime("%Y-%m-%d %H:%M:%S")
    data = []
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
#byebug
      machine_ids = Tenant.find(tenant).machines.where(controller_type: 1).pluck(:id)
      full_log2 = MacroSignal.where(machine_id: machine_ids)
      reason_list = HmiReason.pluck(:spec_id, :name).group_by{|kk| kk[0]}
      machine_log11 = full_log2.select{|a| a[:end_date] >= start_time && a[:update_date] <= end_time}.group_by{|x| x.machine_id}
      mac_ids = machine_log11.keys
      bls = machine_ids - mac_ids
      mer_req = bls.map{|i| [i,[]]}.to_h
      machine_log = machine_log11.merge(mer_req)

###########3
#byebug
# 	 alloc_data = OperatorAllocation.where(shifttransaction_id: shift.id, machine_id: machine_ids, date: date2)
#byebug
#           if alloc_data.present?
#		alloc_data.map do |i|
#byebug
#                op_detail = i.operator_allot_details
#                 if op_detail.present?
#                    @op_name = op_detail.last.operator.id
 ##                else
 #                   @op_name = nil
 #                end
#	       end
#           else
#              @op_name = nil
#           end	 
 
#######
    			  machine_log.each do |mac_reason|
      			  all_data = []
		          cumulate_idle = [] 
#byebug
		          current_idle = MacroSignalOpened.where(machine_id: mac_reason[0], signal: "Reason_id")   
		          if current_idle.present?
			     if (start_time..end_time).include?(current_idle.first.update_date) || current_idle.first.update_date <= start_time
			        current_idle.first[:end_date] = end_time.utc
			         mac_reason.last << current_idle.first
      			     end
		          end
#byebug
		       selected_data = mac_reason.last.select{|i| i.value != 0.0 && i.value != nil}    
		      if selected_data.present?
       
		         if selected_data.count == 1
		           selected_data.first[:update_date] = start_time
		           selected_data.first[:end_date] = end_time
		         else
		           selected_data.first[:update_date] = start_time
		           selected_data.last[:end_date] = end_time
		         end
			 alloc_data = OperatorAllocation.where(shifttransaction_id: shift.id, machine_id: mac_reason[0], date: date2)
                                 if alloc_data.present?
#byebug
                                        op_detail = alloc_data.last.operator_allot_details
                                         if op_detail.present?
                                            op_id = op_detail.all.pluck(:operator_id)
                                            op_name = Operator.where(id: op_id).all.pluck(:operator_name)
                                         else
                                            op_name = nil
                                         end
                                else
                                      op_name = nil
                                end
############
		           selected_data.each do |reason|
	                    if reason_list[reason.value].present?
		               cumulate_idle << {idle_reason: reason_list[reason.value].first[1], idle_start: reason.update_date,  idle_end: reason.end_date, time: (reason.end_date).to_i - (reason.update_date).to_i, operator_name: op_name, operator_id: op_id}
            		    else
	      	               cumulate_idle << {idle_reason: reason_list[reason.value], idle_start: reason.update_date,  idle_end: reason.end_date, time: (reason.end_date).to_i - (reason.update_date).to_i, operator_name: op_name, operator_id: op_id}
            		    end
          		   end
	 	      else
		      end
#				byebug
	#		         alloc_data = OperatorAllocation.where(shifttransaction_id: shift.id, machine_id: mac_reason[0], date: date2)
         #  			 if alloc_data.present?
#byebug
	#		                op_detail = alloc_data.last.operator_allot_details
	#		                 if op_detail.present?
	#		                    op_id = op_detail.all.pluck(:operator_id)
	#				    op_name = Operator.where(id: op_id).all.pluck(:operator_name)
	#		                 else
	#		                    op_name = nil
	#		                 end
	#			else
	#		              op_name = nil
         #  			end
   		      data << {
                	   machine_name: mac_reason[0],
                   	   time: start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"),
	                   date: date,
        	           shift_no: shift_no,
                	   data: cumulate_idle,
                 	   total: cumulate_idle.pluck(:time).sum,
			   operator_name: op_name,
			   operator_id: op_id
                   }
      		 end
          if data.present?

   	     data.each do |data1|
 #    byebug
    	      unless HmiMachineDetail.where(date: data1[:date], shift_no: data1[:shift_no], machine_id: data1[:machine_name]).present?
#byebug
    		     HmiMachineDetail.create(date: data1[:date], shift_no: data1[:shift_no], machine_id: data1[:machine_name],data: data1[:data], operator_id: data1[:op_name])
    	      else
      		rec = HmiMachineDetail.where(date: data1[:date], shift_no: data1[:shift_no], machine_id: data1[:machine_name]).first
        	if rec.present?
          	   rec.update(data: data1[:data])
              	else
        	end
 	      end
     			end

    end

end


  def self.idle_reason_create(tenant, shift_no, date)
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

      t1 = start_time - 5.minutes
      t2 = start_time + 5.minutes
      
      t3 = end_time - 5.minutes
      t4 = end_time + 5.minutes

      byebug
#      MacroSignal.create(update_date:t1, end_date: t2,signal: "Reason_id", value: 19.0, machine_id: 1 )
  end

end
