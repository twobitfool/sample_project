class Response
  attr_accessor :status, :body, :headers

  def initialize
    @status = 200
    @body = ''
    @headers = { 'Content-Type' => 'application/json' }
  end

  def json(data)
    @body = data.to_json
    @headers['Content-Type'] = 'application/json'
  end

end
