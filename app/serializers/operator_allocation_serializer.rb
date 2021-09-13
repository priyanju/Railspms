class OperatorAllocationSerializer < ActiveModel::Serializer
  attributes :id, :description,:date,:created_at,:shifttransaction, :shifttransaction_id,:machine, :machine_id, :created_by,  :operator_allot_details
#  has_one :operator
  has_one :shifttransaction
  has_one :machine
  has_many :operator_allot_details
#  has_many :operator_mapping_allocations

   def machine
    object.machine.machine_name
   end
 
   def machine_id
	object.machine.id
   end

  def shifttransaction
    object.shifttransaction.shift_no
  end

  def shifttransaction_id
    object.shifttransaction.id
  end

  def operator_allot_details
    object.operator_allot_details
  end

 # def to_date
  	
 #   object.to_date.strftime("%d-%m-%Y")
 # end
#   def date
#	object.date.localtime.strftime("%d-%m-%Y %I:%M %p")
 #  end
  def date
   object.date.strftime("%m/%d/%Y")
  end

end
