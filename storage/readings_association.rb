require 'ostruct'
require 'time'
require_relative 'device_and_reading_storage'
require_relative 'reading'


class ReadingsAssociation
  include Enumerable


  def initialize(device_id)
    @device_id = device_id
  end


  def each(&block)
    all.each(&block)
  end


  def all
    DeviceAndReadingStorage.instance.find_readings_by_device_id(@device_id)
  end


  def find_or_create_by(timestamp:, &block)
    storage = DeviceAndReadingStorage.instance
    parsed_timestamp = timestamp.is_a?(Time) ? timestamp : Time.parse(timestamp)
    existing = storage.find_reading_by_device_and_timestamp(@device_id, parsed_timestamp)

    if existing
      existing
    else
      attrs = OpenStruct.new(count: 0)
      yield(attrs) if block_given?
      reading = Reading.new(device_id: @device_id, timestamp: timestamp, count: attrs.count)
      reading.save!
      reading
    end
  end


  def create!(timestamp:, count:)
    reading = Reading.new(device_id: @device_id, timestamp: timestamp, count: count)
    reading.save!
    reading
  end


  def count
    all.size
  end


  def empty?
    all.empty?
  end

end
