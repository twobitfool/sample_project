# frozen_string_literal: true

require "sinatra/base"
require "json"

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

  not_found do
    status 404
    { error: "Not found" }.to_json
  end
end
