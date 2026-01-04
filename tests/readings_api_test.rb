#!/usr/bin/env ruby

require_relative 'test_helper'


class ReadingsAPITest < TestHelper

  def test_post_readings_creates_device_and_readings
    body = {
      id: '36d5658a-6908-479e-887e-a949ec199272',
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 2 },
        { timestamp: '2021-09-29T16:09:15+01:00', count: 15 }
      ]
    }

    res = post_request('/readings', body)

    assert_equal '200', res.code
    response_body = parse_json_body(res)
    assert_equal true, response_body['success']
  end


  def test_post_readings_without_id_returns_400
    body = {
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 2 }
      ]
    }

    res = post_request('/readings', body)

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_equal 'id is required', response_body['error']
  end


  def test_post_readings_without_readings_array_returns_400
    body = {
      id: '36d5658a-6908-479e-887e-a949ec199272'
    }

    res = post_request('/readings', body)

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_equal 'readings array is required', response_body['error']
  end


  def test_get_latest_timestamp_returns_most_recent
    device_id = 'device-latest-test'
    body = {
      id: device_id,
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 2 },
        { timestamp: '2021-09-29T18:08:15+01:00', count: 5 },
        { timestamp: '2021-09-29T17:08:15+01:00', count: 3 }
      ]
    }
    post_request('/readings', body)

    res = get_request("/devices/#{device_id}/latest_timestamp")

    assert_equal '200', res.code
    response_body = parse_json_body(res)
    assert_equal '2021-09-29T17:08:15Z', response_body['latest_timestamp']
  end


  def test_get_latest_timestamp_for_unknown_device_returns_404
    res = get_request('/devices/unknown-device/latest_timestamp')

    assert_equal '404', res.code
    response_body = parse_json_body(res)
    assert_equal 'Device not found', response_body['error']
  end


  def test_get_total_count_returns_total
    device_id = 'device-count-test'
    body = {
      id: device_id,
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 2 },
        { timestamp: '2021-09-29T17:08:15+01:00', count: 15 },
        { timestamp: '2021-09-29T18:08:15+01:00', count: 3 }
      ]
    }
    post_request('/readings', body)

    res = get_request("/devices/#{device_id}/total_count")

    assert_equal '200', res.code
    response_body = parse_json_body(res)
    assert_equal 20, response_body['total_count']
  end


  def test_get_total_count_for_unknown_device_returns_404
    res = get_request('/devices/unknown-device/total_count')

    assert_equal '404', res.code
    response_body = parse_json_body(res)
    assert_equal 'Device not found', response_body['error']
  end


  def test_duplicate_readings_are_ignored
    device_id = 'device-duplicate-test'
    body = {
      id: device_id,
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 10 }
      ]
    }
    post_request('/readings', body)

    # Send duplicate reading with different count
    body_with_duplicate = {
      id: device_id,
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 999 }
      ]
    }
    post_request('/readings', body_with_duplicate)

    res = get_request("/devices/#{device_id}/total_count")
    response_body = parse_json_body(res)

    # Should still be 10, not 999 or 1009
    assert_equal 10, response_body['total_count']
  end


  def test_readings_with_equivalent_timestamps_are_treated_as_duplicates
    device_id = 'device-timezone-test'
    body = {
      id: device_id,
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 10 }
      ]
    }
    post_request('/readings', body)

    # Same instant, different timezone representation (UTC)
    body_with_equivalent = {
      id: device_id,
      readings: [
        { timestamp: '2021-09-29T15:08:15Z', count: 999 }
      ]
    }
    post_request('/readings', body_with_equivalent)

    res = get_request("/devices/#{device_id}/total_count")
    response_body = parse_json_body(res)

    # Should still be 10, the equivalent timestamp should be ignored
    assert_equal 10, response_body['total_count']
  end


  def test_post_readings_with_invalid_timestamp_returns_400
    body = {
      id: 'device-invalid-timestamp',
      readings: [
        { timestamp: 'not-a-valid-timestamp', count: 10 }
      ]
    }

    res = post_request('/readings', body)

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_match(/invalid timestamp/, response_body['error'])
  end


  def test_post_readings_with_missing_timestamp_returns_400
    body = {
      id: 'device-missing-timestamp',
      readings: [
        { count: 10 }
      ]
    }

    res = post_request('/readings', body)

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_equal 'timestamp is required for each reading', response_body['error']
  end


  def test_post_readings_with_non_integer_count_returns_400
    body = {
      id: 'device-invalid-count',
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 'not-a-number' }
      ]
    }

    res = post_request('/readings', body)

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_match(/invalid count/, response_body['error'])
  end


  def test_post_readings_with_float_count_returns_400
    body = {
      id: 'device-float-count',
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00', count: 10.5 }
      ]
    }

    res = post_request('/readings', body)

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_match(/invalid count/, response_body['error'])
  end


  def test_post_readings_with_missing_count_returns_400
    body = {
      id: 'device-missing-count',
      readings: [
        { timestamp: '2021-09-29T16:08:15+01:00' }
      ]
    }

    res = post_request('/readings', body)

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_equal 'count is required for each reading', response_body['error']
  end


  def test_post_readings_with_malformed_json_returns_400
    res = post_request_raw('/readings', '{"id": "test", "readings": [invalid json}', 'application/json')

    assert_equal '400', res.code
    response_body = parse_json_body(res)
    assert_equal 'Malformed JSON payload', response_body['error']
  end

end
