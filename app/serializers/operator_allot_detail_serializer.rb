class OperatorAllotDetailSerializer < ActiveModel::Serializer
  attributes :id, :end_time, :start_time, :operation_management_id, :operation_management, :operator_allocation_id, :operator_id, :operator#, :machine
  has_one :operation_management
  has_one :operator_allocation
  has_one :tenant
  has_one :operator
#  has_one :machine
 
#  def machine
 #    object.machine.machine_name
 # end

  def end_time
	object.end_time.localtime if object.end_time.present?#.strftime("%d-%m-%Y %I:%M %p")
  end


  def start_time
	object.start_time.localtime if object.start_time.present?#.strftime("%d-%m-%Y %I:%M %p")
  end
  def operator_id
    object.operator.id 
  end
  
  def operator
    object.operator.operator_name	
  end

  def operation_management_id
    object.operation_management.id
  end

  def operation_management
    object.operation_management.operation_id	
  end

  def operation_management_name
    object.operation_management.operation_name
  end

end
