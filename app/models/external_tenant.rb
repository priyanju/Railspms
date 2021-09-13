class ExternalTenant < ActiveRecord::Base

  serialize :machine_type, Array
  self.abstract_class = true 
  establish_connection("#{Rails.env}_sec".to_sym)
  self.table_name = "tenants"

end
