require 'json'


class Request
  attr_reader :params, :query, :body, :path, :method


  def initialize(webrick_req, route_params = {})
    @path = webrick_req.path
    @method = webrick_req.request_method
    @params = route_params
    @query = webrick_req.query

    # Parse JSON body if present
    if webrick_req.body && !webrick_req.body.empty?
      begin
        @body = JSON.parse(webrick_req.body)
      rescue JSON::ParserError
        @body = webrick_req.body
      end
    else
      @body = nil
    end
  end

end
