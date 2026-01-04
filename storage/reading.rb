require 'time'
require_relative 'device_and_reading_storage'


class Reading
  attr_reader :id, :device_id, :timestamp
  attr_accessor :count


  def initialize(device_id:, timestamp:, count:)
    @id = nil
    @device_id = device_id
    @timestamp = timestamp.is_a?(Time) ? timestamp : Time.parse(timestamp)
    @count = count.to_i
  end


  def save!
    unless @id
      DeviceAndReadingStorage.instance.add_reading(self)
    end
    self
  end


  def persisted?
    !@id.nil?
  end

end
