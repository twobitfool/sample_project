#!/usr/bin/env ruby

require_relative 'test_helper'

class APIServerTest < TestHelper
  def test_ping_returns_hello_world_message
    res = get_request('/ping')

    assert_equal '200', res.code
    assert_includes res['content-type'], 'application/json'

    body = parse_json_body(res)
    assert_equal 'Hello world!', body['message']
    assert_equal 'ok', body['status']
  end

  def test_bad_url_returns_404
    res = get_request('/this/route/does/not/exist')

    assert_equal '404', res.code
    assert_includes res['content-type'], 'application/json'

    body = parse_json_body(res)
    assert_equal 'Not Found', body['error']
  end
end
