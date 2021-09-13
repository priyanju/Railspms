class HmiMachineDetailSerializer < ActiveModel::Serializer
    attributes :id, :machine_name, :machine_id, :shift_no, :date, :data, :operator_name

  def operator_id
	if object.operator_id == nil
	 "Not Assigned" 
    else
      object.operator.operator_spec_id
    end
  end

  def operator_name1
  	if object.operator_id == nil
  		"Not Assigned"
  	else
  		object.operator.operator_name
  	end
  end

  def machine_name
    object.machine.machine_name
  end

  def operator_name
	if object.data == nil
	 	"Not Assigned"
	else
	   object.data.pluck("operator_name").uniq.flatten	  
	end	
  end

#  def machine_id
#  	object.machine.machine_type
#  end

#  def duration
#  	 object.start_time.localtime.strftime('%H:%M:%S')+' - '+object.end_time.localtime.strftime('%H:%M:%S')
#  end

 # def time
#    object.shifttransaction.shift_start_time+' - '+object.shifttransaction.shift_end_time
 # end

#  def idle_time
#    Time.at(object.duration).utc.strftime("%H:%M:%S")
#  end


end
