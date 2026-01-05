class ApplicationController < ActionController::API
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

  def ping
    render json: { message: "Hello world!", status: "ok" }
  end

  private

  def handle_parse_error(_exception)
    render json: { error: "Malformed JSON payload" }, status: :bad_request
  end
end
