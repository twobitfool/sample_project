require 'minitest/autorun'
require 'json'
require 'net/http'
require 'uri'

class TestHelper < Minitest::Test
  PORT = ENV['TEST_PORT'] || 8080

  def get_request(path)
    uri = URI("http://localhost:#{PORT}#{path}")
    Net::HTTP.get_response(uri)
  end

  def post_request(path, body)
    uri = URI("http://localhost:#{PORT}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = body.to_json
    http.request(request)
  end

  def post_request_raw(path, raw_body, content_type = 'application/json')
    uri = URI("http://localhost:#{PORT}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => content_type })
    request.body = raw_body
    http.request(request)
  end

  def parse_json_body(response)
    JSON.parse(response.body)
  end
end
