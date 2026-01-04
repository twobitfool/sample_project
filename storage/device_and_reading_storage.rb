require 'singleton'
require 'time'

# Singleton class that holds in-memory storage for devices and readings
class DeviceAndReadingStorage
  include Singleton

  attr_reader :devices, :readings


  def initialize
    @devices = []
    @readings = []
    @next_device_id = 1
    @next_reading_id = 1
  end


  def add_device(device)
    device.instance_variable_set(:@id, @next_device_id)
    @next_device_id += 1
    @devices << device
    device
  end


  def find_device_by_id(id)
    @devices.find { |device| device.id == id }
  end


  def find_device_by_uid(uid)
    @devices.find { |device| device.uid == uid }
  end


  def add_reading(reading)
    reading.instance_variable_set(:@id, @next_reading_id)
    @next_reading_id += 1
    @readings << reading
    reading
  end


  def find_readings_by_device_id(device_id)
    @readings.select { |reading| reading.device_id == device_id }
  end


  def find_reading_by_device_and_timestamp(device_id, timestamp)
    target_time = timestamp.is_a?(Time) ? timestamp : Time.parse(timestamp)
    @readings.find do |reading|
      reading.device_id == device_id && reading.timestamp == target_time
    end
  end


  def reset!
    @devices = []
    @readings = []
    @next_device_id = 1
    @next_reading_id = 1
  end
end
