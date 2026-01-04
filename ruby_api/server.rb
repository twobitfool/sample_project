#!/usr/bin/env ruby

require 'time'
require_relative 'lib/app'
require_relative '../storage/device'


class DeviceAPI < App

  get '/ping' do |req, res|
    res.json({ message: 'Hello world!', status: 'ok' })
  end


  # Store readings for a device
  post '/readings' do |req, res|
    device_uid = req.body['id']
    readings_data = req.body['readings']

    halt 400, 'id is required' if device_uid.nil? || device_uid.empty?
    halt 400, 'readings array is required' if readings_data.nil? || !readings_data.is_a?(Array)

    validate_readings!(readings_data)

    device = Device.find_by_uid(device_uid) || Device.create!(uid: device_uid)

    readings_data.each do |reading|
      device.readings.find_or_create_by(timestamp: reading['timestamp']) do |r|
        r.count = reading['count']
      end
    end

    res.status = 200
    res.json({ success: true })
  end


  # Get the latest timestamp for a device
  get '/devices/:id/latest_timestamp' do |req, res|
    device = find_device!(req.params['id'])
    latest = device.latest_timestamp
    res.json({ latest_timestamp: latest&.utc&.iso8601 })
  end


  # Get the total count for a device
  get '/devices/:id/total_count' do |req, res|
    device = find_device!(req.params['id'])
    res.json({ total_count: device.total_count })
  end


  def find_device!(uid)
    device = Device.find_by_uid(uid)
    halt 404, 'Device not found' if device.nil?
    device
  end


  def validate_readings!(readings_data)
    readings_data.each do |reading|
      timestamp = reading['timestamp']
      count = reading['count']

      halt 400, 'timestamp is required for each reading' if timestamp.nil? || timestamp.to_s.empty?

      begin
        Time.parse(timestamp.to_s)
      rescue ArgumentError
        halt 400, "invalid timestamp: #{timestamp}"
      end

      halt 400, 'count is required for each reading' if count.nil?

      unless count.is_a?(Integer)
        halt 400, "invalid count: #{count} (must be an integer)"
      end

      if count < 0
        halt 400, "invalid count: #{count} (must be non-negative)"
      end
    end
  end

end


if __FILE__ == $0
  app = DeviceAPI.new
  port = ENV['PORT'] || 3000
  app.start(port: port.to_i)
end
