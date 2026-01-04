# A simple DSL for defining routes
class Router

  def initialize
    @routes = Hash.new { |h, k| h[k] = {} }
  end


  def get(path, &block)
    add_route('GET', path, block)
  end


  def post(path, &block)
    add_route('POST', path, block)
  end


  def add_route(method, path, handler)
    # Convert the path (with :params) to regex pattern
    pattern = path.gsub(/:(\w+)/) { "(?<#{$1}>[^/]+)" }
    regex = /^#{pattern}$/
    @routes[method][regex] = { handler: handler, path: path }
  end


  def match(method, path)
    return nil unless @routes[method]

    @routes[method].each do |regex, route_info|
      if match_data = regex.match(path)
        # Extract named params from the path
        params = match_data.names.each_with_object({}) do |name, hash|
          hash[name] = match_data[name]
        end
        return { handler: route_info[:handler], params: params }
      end
    end
    nil
  end

end
