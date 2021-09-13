class ProcessPlan < ApplicationRecord
acts_as_paranoid
  belongs_to :tenant
  belongs_to :part_configuration
  has_one :operation_management, dependent: :destroy

  validates :plan_number, uniqueness: true
  validates :plan_name, uniqueness: true
  validates_uniqueness_of :part_configuration_id
  

  enum status: { "Active": 1, "Inactive": 2}
end
