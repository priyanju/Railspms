class PartConfiguration < ApplicationRecord
acts_as_paranoid
  belongs_to :tenant
  belongs_to :role
  has_one :process_plan, dependent: :destroy

  validates :part_number, uniqueness: true

  enum status: { "Active": 1, "Inactive": 2}
  
end
