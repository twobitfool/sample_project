class DevicesController < ApplicationController
  before_action :find_device

  def latest_timestamp
    latest = @device.latest_timestamp
    render json: { latest_timestamp: latest&.utc&.iso8601 }
  end

  def total_count
    render json: { total_count: @device.total_count }
  end

  private

  def find_device
    @device = Device.find_by_uid(params[:id])
    unless @device
      render json: { error: "Device not found" }, status: :not_found
    end
  end
end
