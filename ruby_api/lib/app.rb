require 'webrick'
require_relative 'router'
require_relative 'request'
require_relative 'response'


# A simple API framework (in the spirit of Sinatra)
class App

  def initialize(&block)
    @router = Router.new
    instance_eval(&block) if block_given?
  end


  def get(path, &block)
    @router.get(path, &block)
  end


  def post(path, &block)
    @router.post(path, &block)
  end


  def call(webrick_req, webrick_res)
    route = @router.match(webrick_req.request_method, webrick_req.path)

    if route
      req = Request.new(webrick_req, route[:params])
      res = Response.new

      begin
        route[:handler].call(req, res)

        webrick_res.status = res.status
        webrick_res.body = res.body
        res.headers.each { |k, v| webrick_res[k] = v }
      rescue => e
        webrick_res.status = 500
        webrick_res.body = { error: e.message }.to_json
        webrick_res['Content-Type'] = 'application/json'
      end
    else
      webrick_res.status = 404
      webrick_res.body = { error: 'Not Found' }.to_json
      webrick_res['Content-Type'] = 'application/json'
    end
  end


  def start(port: 3000)
    server = WEBrick::HTTPServer.new(
      Port: port,
      Logger: WEBrick::Log.new('/dev/null'),
      AccessLog: []
    )

    server.mount_proc '/' do |req, res|
      call(req, res)
    end

    trap('INT') { server.shutdown }

    puts "Server starting on http://localhost:#{port}"
    server.start
  end

end
