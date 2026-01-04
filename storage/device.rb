require_relative 'device_and_reading_storage'
require_relative 'readings_association'


class Device
  attr_reader :id, :uid


  def initialize(uid:)
    @id = nil
    @uid = uid
  end


  def save!
    unless @id
      storage = DeviceAndReadingStorage.instance
      if storage.find_device_by_uid(@uid)
        raise "Device with uid '#{@uid}' already exists"
      end
      storage.add_device(self)
    end
    self
  end


  def persisted?
    !@id.nil?
  end


  def readings
    raise "Device must be persisted before accessing readings" unless persisted?
    @readings_association ||= ReadingsAssociation.new(@id)
  end


  def total_count
    readings.sum(&:count)
  end


  def latest_timestamp
    readings.map(&:timestamp).max
  end


  class << self

    def find(id)
      DeviceAndReadingStorage.instance.find_device_by_id(id)
    end


    def find_by_uid(uid)
      DeviceAndReadingStorage.instance.find_device_by_uid(uid)
    end


    def create!(uid:)
      device = new(uid: uid)
      device.save!
      device
    end

  end

end
