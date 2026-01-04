#!/usr/bin/env ruby

require_relative 'lib/app'


def create_app
  App.new do

    get '/ping' do |req, res|
      res.json({ message: 'Hello world!', status: 'ok' })
    end

  end
end


if __FILE__ == $0
  app = create_app
  port = ENV['PORT'] || 3000
  app.start(port: port.to_i)
end
