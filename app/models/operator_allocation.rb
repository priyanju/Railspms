class OperatorAllocation < ApplicationRecord
# belongs_to :operator, -> { with_deleted }
  belongs_to :shifttransaction, -> { with_deleted }
  belongs_to :machine, -> { with_deleted }
  has_many :operator_mapping_allocations,:dependent => :destroy
  has_many :operator_allot_details,:dependent => :destroy
  accepts_nested_attributes_for :operator_allot_details
  after_create :after_savei1
  after_update :after_update_att

  validates_uniqueness_of :date, scope: %i[machine_id shifttransaction_id]
#  validates_uniqueness_of :date, scope: [:shifttransaction_id, :machine_id]
#  validates_uniquness_of :date, if: Proc.new { |a| a.operator_allocation.shifttransaction_id.present? && a.operator_allocation.machine_id.present? }

  def after_savei1
   date = self.date.strftime("%Y-%m-%d")
   shift = self.shifttransaction
   case
     when shift.day == 1 && shift.end_day == 1
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time
     when shift.day == 1 && shift.end_day == 2
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
     when shift.day == 2 && shift.end_day == 2
      start_time = (date+" "+shift.shift_start_time).to_time+1.day
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
     end
  
   if self.operator_allot_details.count == 1
    self.operator_allot_details.each do |aloct_detail|
      aloct_detail.update(start_time: start_time, end_time: end_time)
    end
   end
  end
  
  def after_update_att
   date = self.date.strftime("%Y-%m-%d")
   shift = self.shifttransaction
   case
     when shift.day == 1 && shift.end_day == 1
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time
     when shift.day == 1 && shift.end_day == 2
      start_time = (date+" "+shift.shift_start_time).to_time
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
     when shift.day == 2 && shift.end_day == 2
      start_time = (date+" "+shift.shift_start_time).to_time+1.day
      end_time = (date+" "+shift.shift_end_time).to_time+1.day
     end
  if (start_time..end_time).include?(Time.now)
    if self.operator_allot_details.count > 1
      ttime = Time.now
      self.operator_allot_details[-2].update(end_time: ttime)
      self.operator_allot_details[-1].update(start_time: ttime, end_time: end_time)
    end
  end
end
end
