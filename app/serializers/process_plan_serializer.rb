class ProcessPlanSerializer < ActiveModel::Serializer
  attributes :id, :plan_number, :plan_name, :part_number, :plan_description, :part_configuration_id, :created_by, :status, :deleted_at
  has_one :tenant 
  has_one :part_configuration


  def part_number
     object.part_configuration.part_number if object.part_configuration.present?
  end
end
