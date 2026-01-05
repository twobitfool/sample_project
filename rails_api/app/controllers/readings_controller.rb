require "time"

class ReadingsController < ApplicationController
  def create
    device_uid = params[:id]
    readings_data = params[:readings]

    if device_uid.nil? || device_uid.to_s.empty?
      return render json: { error: "id is required" }, status: :bad_request
    end

    if readings_data.nil? || !readings_data.is_a?(Array)
      return render json: { error: "readings array is required" }, status: :bad_request
    end

    validation_error = validate_readings(readings_data)
    if validation_error
      return render json: { error: validation_error }, status: :bad_request
    end

    device = Device.find_or_create_by!(uid: device_uid)

    readings_data.each do |reading_data|
      timestamp = Time.parse(reading_data["timestamp"].to_s)
      count = reading_data["count"].to_i

      unless device.readings.exists?(timestamp: timestamp)
        device.readings.create!(timestamp: timestamp, count: count)
      end
    end

    render json: { success: true }, status: :ok
  end

  private

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
