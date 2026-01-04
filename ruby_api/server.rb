#!/usr/bin/env ruby

require_relative 'lib/app'


class DeviceAPI < App

  get '/ping' do |req, res|
    res.json({ message: 'Hello world!', status: 'ok' })
  end

end


if __FILE__ == $0
  app = DeviceAPI.new
  port = ENV['PORT'] || 3000
  app.start(port: port.to_i)
end
