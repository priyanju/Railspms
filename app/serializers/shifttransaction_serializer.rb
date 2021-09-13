class ShifttransactionSerializer < ActiveModel::Serializer
  attributes :id,:start_noon,:end_noon,:shift_start_time,:shift_end_time,:actual_working_hours,:shift_no,:shift_start_time_dummy,:shift_end_time_dummy,:actual_working_hours_dummy,:day,:end_day, :break_time, :actual_working_without_break
  def start_noon
   object.shift_start_time.to_time.strftime("%p")
  end
  def end_noon
   object.shift_end_time.to_time.strftime("%p")
  end
  def day
   object.day.to_s
  end
  def end_day
   object.end_day.to_s
  end
  def break_time
   Time.at(object.break_time.to_i).utc.strftime("%H:%M:%S")#object.break_time.to_i 
  end
  def actual_working_hours
   Time.at(object.actual_working_hours.to_i).utc.strftime("%H:%M:%S")#object.break_time.to_i
  end
end
