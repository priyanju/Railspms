class AlarmReport < ApplicationRecord
  belongs_to :machine
  belongs_to :shift
  belongs_to :tenant, optional: true
  belongs_to :operator, optional: true

  def self.de_rec  	
  	Machine.last.machine_daily_logs.delete_all
  	Machine.last.machine_logs.delete_all
  	Machine.last.parts.delete_all
  	Machine.last.current_part.delete
$redis.flushall
  end
end
