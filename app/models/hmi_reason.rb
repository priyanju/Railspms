class HmiReason < ApplicationRecord

validates :spec_id, uniqueness: true
validates :name, :spec_id, presence: true
validates :name, uniqueness: true


def self.idle_report(tenant, shift, date)
  date = date.to_s
  shift = Shifttransaction.find_by(shift_no: shift)
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
  
   machines = Machine.where(tenant_id: tenant)
   machines.each do |mac|
   byebug
   end
end



end
