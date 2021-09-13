class PartConfigurationSerializer < ActiveModel::Serializer
  attributes :id, :part_number, :part_name, :customer_name, :status, :part_description, :created_by
  has_one :tenant
#  has_one :role
end
