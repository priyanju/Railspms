class TenantSerializer < ActiveModel::Serializer
  attributes :id,:tenant_name,:address_line1,:address_line2,:city,:state,:country,:created_at#,:role_name
  has_many :users
  #has_many :ethernet_logs
end
