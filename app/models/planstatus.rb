class Planstatus < ApplicationRecord
has_many :cncoperations,:dependent => :destroy
belongs_to :machine
 
  def self.ex_create(tenant, shift_no, date)
    date = date
     shifts = Shifttransaction.includes(:shift).where(shifts: {tenant_id: tenant})
     shift = shifts.find_by_shift_no(shift_no)

     case
      when shift.day == 1 && shift.end_day == 1
        start_time = (date+" "+shift.shift_start_time).to_time
        end_time = (date+" "+shift.shift_end_time).to_time
      when shift.day == 1 && shift.end_day == 2
        start_time = (date+" "+shift.shift_start_time).to_time
        end_time = (date+" "+shift.shift_end_time).to_time+1.day
      else
        start_time = (date+" "+shift.shift_start_time).to_time+1.day
        end_time = (date+" "+shift.shift_end_time).to_time+1.day
      end
     byebug
   end


end
