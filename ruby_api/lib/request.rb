require 'json'


class MalformedJSONError < StandardError
  def message
    'Malformed JSON payload'
  end
end


class Request
  attr_reader :params, :query, :body, :path, :method


  def initialize(webrick_req, route_params = {})
    @path = webrick_req.path
    @method = webrick_req.request_method
    @params = route_params
    @query = webrick_req.query

    # Parse JSON body if present
    if webrick_req.body && !webrick_req.body.empty?
      content_type = webrick_req['Content-Type'] || ''
      is_json_request = content_type.include?('application/json')

      begin
        @body = JSON.parse(webrick_req.body)
      rescue JSON::ParserError => e
        if is_json_request
          raise MalformedJSONError
        else
          # For non-JSON requests, keep raw body
          @body = webrick_req.body
        end
      end
    else
      @body = nil
    end
  end

end
