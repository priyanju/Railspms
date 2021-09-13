class PartCofigurationSerializer < ActiveModel::Serializer
  attributes :id, :part_number, :part_name, :customer_name, :is_active, :part_description, :references
  has_one :role
end
