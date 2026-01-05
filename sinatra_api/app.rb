# frozen_string_literal: true

require "sinatra/base"
require "json"
require "time"
require_relative "../storage/device"


class DeviceNotFound < StandardError; end


class DeviceAPI < Sinatra::Base


  configure do
    set :show_exceptions, false
  end


  before do
    content_type :json
  end


  get "/ping" do
    { message: "Hello world!", status: "ok" }.to_json
  end


  post "/readings" do
    body = parse_json_body
    return if body.nil?

    device_uid = body["id"]
    readings_data = body["readings"]

    if device_uid.nil? || device_uid.to_s.empty?
      halt 400, { error: "id is required" }.to_json
    end

    if readings_data.nil? || !readings_data.is_a?(Array)
      halt 400, { error: "readings array is required" }.to_json
    end

    error = validate_readings(readings_data)
    halt 400, { error: error }.to_json if error

    device = Device.find_by_uid(device_uid) || Device.create!(uid: device_uid)

    readings_data.each do |reading|
      device.readings.find_or_create_by(timestamp: reading["timestamp"]) do |r|
        r.count = reading["count"]
      end
    end

    { success: true }.to_json
  end


  get "/devices/:id/latest_timestamp" do
    device = find_device!(params[:id])
    latest = device.latest_timestamp
    { latest_timestamp: latest&.utc&.iso8601 }.to_json
  end


  get "/devices/:id/total_count" do
    device = find_device!(params[:id])
    { total_count: device.total_count }.to_json
  end


  not_found do
    { error: "Not Found" }.to_json
  end


  error DeviceNotFound do
    status 404
    { error: "Device not found" }.to_json
  end


  error do
    { error: "Internal server error" }.to_json
  end


  private


  def parse_json_body
    raw_body = env["rack.input"].read
    env["rack.input"].rewind if env["rack.input"].respond_to?(:rewind)
    JSON.parse(raw_body)
  rescue JSON::ParserError
    halt 400, { error: "Malformed JSON payload" }.to_json
  end


  def find_device!(uid)
    Device.find_by_uid(uid) or raise DeviceNotFound
  end


  def validate_readings(readings_data)
    readings_data.each do |reading|
      timestamp = reading["timestamp"]
      count = reading["count"]

      if timestamp.nil? || timestamp.to_s.empty?
        return "timestamp is required for each reading"
      end

      begin
        Time.parse(timestamp.to_s)
      rescue ArgumentError
        return "invalid timestamp: #{timestamp}"
      end

      if count.nil?
        return "count is required for each reading"
      end

      unless count.is_a?(Integer)
        return "invalid count: #{count} (must be an integer)"
      end

      if count < 0
        return "invalid count: #{count} (must be non-negative)"
      end
    end

    nil
  end
end
