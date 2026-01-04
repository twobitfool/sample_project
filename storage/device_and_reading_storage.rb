require 'singleton'
require 'time'

# Singleton class that holds in-memory storage for devices and readings
class DeviceAndReadingStorage
  include Singleton


  def initialize
    @devices_by_id = {}
    @devices_by_uid = {}
    @readings_by_device_id = {}
    @next_device_id = 1
    @next_reading_id = 1
  end


  def add_device(device)
    device.instance_variable_set(:@id, @next_device_id)
    @devices_by_id[@next_device_id] = device
    @devices_by_uid[device.uid] = device
    @next_device_id += 1
    device
  end


  def find_device_by_id(id)
    @devices_by_id[id]
  end


  def find_device_by_uid(uid)
    @devices_by_uid[uid]
  end


  def add_reading(reading)
    reading.instance_variable_set(:@id, @next_reading_id)
    device_id = reading.device_id
    @readings_by_device_id[device_id] ||= []
    @readings_by_device_id[device_id] << reading
    @next_reading_id += 1
    reading
  end


  def find_readings_by_device_id(device_id)
    @readings_by_device_id[device_id] || []
  end


  def find_reading_by_device_and_timestamp(device_id, timestamp)
    target_time = timestamp.is_a?(Time) ? timestamp : Time.parse(timestamp)
    readings = @readings_by_device_id[device_id] || []
    readings.find { |reading| reading.timestamp == target_time }
  end


  def devices
    @devices_by_id.values
  end


  def readings
    @readings_by_device_id.values.flatten
  end


  def reset!
    @devices_by_id = {}
    @devices_by_uid = {}
    @readings_by_device_id = {}
    @next_device_id = 1
    @next_reading_id = 1
  end
end
