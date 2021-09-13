class MacroSignalSerializer < ActiveModel::Serializer
  attributes :id, :update_date, :end_date, :time_stamp, :signal, :value
  has_one :machine
end
