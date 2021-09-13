class OperatorSerializer < ActiveModel::Serializer
  attributes :id, :operator_name, :operator_spec_id, :description, :tenant_id, :created_by
	
 # attribute :operator_name,if: :condition?

# def condition?
#	false
# end

# attributes :operator_name do |object|
#	object.operator_name	
# end if false


end

