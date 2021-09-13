class OperationManagementSerializer < ActiveModel::Serializer
	attributes :id, :operation_name, :operation_id, :std_cycle_time, :load_unload_time, :setup_time, :created_by, :status, :part_per_cycle, :process_plan_id, :plan_number, :process_plan
#  has_one :part_configuration
#  has_one :process_plan
  has_one :tenant
   
  def std_cycle_time
	Time.at(object.std_cycle_time).utc.strftime("%H:%M:%S")
  end
 
  def load_unload_time
	Time.at(object.load_unload_time).utc.strftime("%H:%M:%S")
  end
  
  def setup_time
	Time.at(object.setup_time).utc.strftime("%H:%M:%S")
  end
 
  def plan_number
        object.process_plan.plan_number if object.process_plan.present? 
  end
 
end
