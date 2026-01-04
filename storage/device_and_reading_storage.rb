require 'singleton'
require 'time'

# Singleton class that holds in-memory storage for devices and readings
class DeviceAndReadingStorage
  include Singleton

  # Note: Using `instance_variable_set` to set the `id` attribute on the device
  # and reading to make this feel like a database-backed ORM where the database
  # is automatically incrementing the `id` attribute.

  def initialize
    @devices_by_id = {}
    @devices_by_uid = {}
    @readings_by_device_id = {}
    @readings_by_device_id_and_timestamp = {}
    @device_cache = {}
    @next_device_id = 1
    @next_reading_id = 1
  end


  def add_device(device)
    device.instance_variable_set(:@id, @next_device_id)
    @devices_by_id[@next_device_id] = device
    @devices_by_uid[device.uid] = device
    @device_cache[@next_device_id] = { total_count: 0, latest_timestamp: nil }
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
    @readings_by_device_id_and_timestamp[device_id] ||= {}
    @readings_by_device_id_and_timestamp[device_id][reading.timestamp] = reading
    @next_reading_id += 1
    update_device_cache_for_reading(reading)
    reading
  end


  def update_device_cache_for_reading(reading)
    cache = @device_cache[reading.device_id]
    return unless cache

    cache[:total_count] += reading.count

    if cache[:latest_timestamp].nil? || reading.timestamp > cache[:latest_timestamp]
      cache[:latest_timestamp] = reading.timestamp
    end
  end


  def get_device_total_count(device_id)
    cache = @device_cache[device_id]
    cache ? cache[:total_count] : 0
  end


  def get_device_latest_timestamp(device_id)
    cache = @device_cache[device_id]
    cache ? cache[:latest_timestamp] : nil
  end


  def find_readings_by_device_id(device_id)
    @readings_by_device_id[device_id] || []
  end


  def find_reading_by_device_and_timestamp(device_id, timestamp)
    target_time = timestamp.is_a?(Time) ? timestamp : Time.parse(timestamp)
    device_readings = @readings_by_device_id_and_timestamp[device_id]
    device_readings ? device_readings[target_time] : nil
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
    @readings_by_device_id_and_timestamp = {}
    @device_cache = {}
    @next_device_id = 1
    @next_reading_id = 1
  end
end
