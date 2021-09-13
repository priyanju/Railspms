class OperationManagement < ApplicationRecord
acts_as_paranoid
  belongs_to :part_configuration
  belongs_to :process_plan
  belongs_to :tenant
  has_many :operator_allot_details

  validates :operation_id, uniqueness: true

  enum status: { "Active": 1, "Inactive": 2}


  def get_operation_management(params)
    @operation_management = OperationManagement.(operation_name: params[:operation_name],operation_id: params[:operation_id], std_cycle_time: Time.at(params[:std_cycle_time].to_time).utc.strftime("%H:%M:%S"), load_unload_time: Time.at(params[:load_unload_time].to_time).utc.strftime("%H:%M:%S"), setup_time: Time.at(params[:setup_time].to_time).utc.strftime("%H:%M:%S"), created_by: params[:created_by], status: params[:status], part_per_cycle: params[:part_per_cycle], part_configuration_id: params[:part_configuration_id], process_plan_id: params[:process_plan_id], tenant_id: params[:tenant_id])
#    @operation_management.load_unload_time = Time.at(params[:load_unload_time].to_time).utc.strftime("%H:%M:%S")
  end
end
