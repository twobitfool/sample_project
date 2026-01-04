require 'minitest/autorun'
require 'time'
require_relative '../storage/device'


class DeviceTest < Minitest::Test

  def setup
    DeviceAndReadingStorage.instance.reset!
  end


  def test_create_assigns_id
    device = Device.create!(uid: 'device-001')
    refute_nil device.id
    assert_equal 1, device.id
  end


  def test_create_stores_uid
    device = Device.create!(uid: 'device-001')
    assert_equal 'device-001', device.uid
  end


  def test_create_requires_uid
    assert_raises(ArgumentError) { Device.create! }
  end


  def test_create_rejects_duplicate_uid
    Device.create!(uid: 'device-001')
    error = assert_raises(RuntimeError) { Device.create!(uid: 'device-001') }
    assert_match(/already exists/, error.message)
  end


  def test_create_multiple_devices_have_unique_ids
    device1 = Device.create!(uid: 'device-001')
    device2 = Device.create!(uid: 'device-002')
    assert_equal 1, device1.id
    assert_equal 2, device2.id
  end


  def test_find_returns_device
    device = Device.create!(uid: 'device-001')
    found = Device.find(device.id)
    assert_equal device.id, found.id
  end


  def test_find_returns_nil_when_not_found
    result = Device.find(999)
    assert_nil result
  end


  def test_find_by_uid_returns_device
    device = Device.create!(uid: 'device-001')
    found = Device.find_by_uid('device-001')
    assert_equal device.id, found.id
    assert_equal 'device-001', found.uid
  end


  def test_find_by_uid_returns_nil_when_not_found
    result = Device.find_by_uid('nonexistent')
    assert_nil result
  end


  def test_save_persists_device
    device = Device.new(uid: 'device-001')
    refute device.persisted?
    device.save!
    assert device.persisted?
    refute_nil device.id
  end


  def test_readings_returns_association
    device = Device.create!(uid: 'device-001')
    assert_instance_of ReadingsAssociation, device.readings
  end


  def test_readings_raises_if_not_persisted
    device = Device.new(uid: 'device-001')
    assert_raises(RuntimeError) { device.readings }
  end


  def test_readings_find_or_create_by_creates_new_reading
    device = Device.create!(uid: 'device-001')
    reading = device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") do |r|
      r.count = 5
    end

    assert_equal 5, reading.count
    assert_instance_of Time, reading.timestamp
    assert_equal Time.parse("2024-01-01T00:00:00Z"), reading.timestamp
    assert_equal device.id, reading.device_id
    refute_nil reading.id
  end


  def test_readings_timestamp_is_cast_to_time
    device = Device.create!(uid: 'device-001')
    reading = device.readings.find_or_create_by(timestamp: "2024-01-01T12:30:00Z") do |r|
      r.count = 5
    end

    assert_instance_of Time, reading.timestamp
  end


  def test_readings_count_is_integer
    device = Device.create!(uid: 'device-001')
    reading = device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") do |r|
      r.count = "42"
    end

    assert_equal 42, reading.count
    assert_instance_of Integer, reading.count
  end


  def test_readings_find_or_create_by_returns_existing_reading
    device = Device.create!(uid: 'device-001')
    reading1 = device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") do |r|
      r.count = 5
    end

    reading2 = device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") do |r|
      r.count = 999
    end

    assert_equal reading1.id, reading2.id
    assert_equal 5, reading2.count
  end


  def test_readings_find_or_create_by_matches_equivalent_timestamps_with_different_offsets
    device = Device.create!(uid: 'device-001')
    reading1 = device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") do |r|
      r.count = 5
    end

    # Same instant in time, different timezone representation
    reading2 = device.readings.find_or_create_by(timestamp: "2024-01-01T01:00:00+01:00") do |r|
      r.count = 999
    end

    assert_equal reading1.id, reading2.id
    assert_equal 5, reading2.count
    assert_equal 1, device.readings.count
  end


  def test_readings_are_scoped_to_device
    device1 = Device.create!(uid: 'device-001')
    device2 = Device.create!(uid: 'device-002')

    device1.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 1 }
    device1.readings.find_or_create_by(timestamp: "2024-01-02T00:00:00Z") { |r| r.count = 2 }
    device2.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 10 }

    assert_equal 2, device1.readings.count
    assert_equal 1, device2.readings.count
  end


  def test_readings_enumerable
    device = Device.create!(uid: 'device-001')
    device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 1 }
    device.readings.find_or_create_by(timestamp: "2024-01-02T00:00:00Z") { |r| r.count = 2 }

    counts = device.readings.map(&:count)
    assert_equal [1, 2], counts
  end


  def test_readings_empty
    device = Device.create!(uid: 'device-001')
    assert device.readings.empty?

    device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 1 }
    refute device.readings.empty?
  end


  def test_total_count_returns_zero_with_no_readings
    device = Device.create!(uid: 'device-001')
    assert_equal 0, device.total_count
  end


  def test_total_count_sums_all_reading_counts
    device = Device.create!(uid: 'device-001')
    device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 5 }
    device.readings.find_or_create_by(timestamp: "2024-01-02T00:00:00Z") { |r| r.count = 10 }
    device.readings.find_or_create_by(timestamp: "2024-01-03T00:00:00Z") { |r| r.count = 3 }

    assert_equal 18, device.total_count
  end


  def test_total_count_unaffected_by_duplicate_timestamp
    device = Device.create!(uid: 'device-001')
    device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 5 }
    device.readings.find_or_create_by(timestamp: "2024-01-02T00:00:00Z") { |r| r.count = 10 }

    assert_equal 15, device.total_count

    # Attempt to add duplicate timestamp with different count
    device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 100 }

    assert_equal 15, device.total_count
    assert_equal 2, device.readings.count
  end


  def test_latest_timestamp_returns_nil_with_no_readings
    device = Device.create!(uid: 'device-001')
    assert_nil device.latest_timestamp
  end


  def test_latest_timestamp_returns_most_recent
    device = Device.create!(uid: 'device-001')

    # Note: This test is sending the timestamps out of order, to make sure the
    # latest_timestamp method correctly returns the most recent timestamp.
    device.readings.find_or_create_by(timestamp: "2024-01-01T00:00:00Z") { |r| r.count = 1 }
    device.readings.find_or_create_by(timestamp: "2024-01-03T00:00:00Z") { |r| r.count = 2 }
    device.readings.find_or_create_by(timestamp: "2024-01-02T00:00:00Z") { |r| r.count = 3 }

    assert_equal Time.parse("2024-01-03T00:00:00Z"), device.latest_timestamp
  end

end
