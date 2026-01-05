// In-memory storage for devices and readings

class Storage {

  constructor() {
    this.reset();
  }


  reset() {
    this.devicesById = new Map();
    this.devicesByUid = new Map();
    this.readingsByDeviceIdAndTimestamp = new Map();
    this.deviceCache = new Map();
    this.nextDeviceId = 1;
    this.nextReadingId = 1;
  }


  addDevice(device) {
    device.id = this.nextDeviceId;
    this.devicesById.set(this.nextDeviceId, device);
    this.devicesByUid.set(device.uid, device);
    this.deviceCache.set(this.nextDeviceId, { totalCount: 0, latestTimestamp: null });
    this.nextDeviceId++;
    return device;
  }


  findDeviceByUid(uid) {
    return this.devicesByUid.get(uid) || null;
  }


  addReading(reading) {
    reading.id = this.nextReadingId;
    const deviceId = reading.deviceId;

    if (!this.readingsByDeviceIdAndTimestamp.has(deviceId)) {
      this.readingsByDeviceIdAndTimestamp.set(deviceId, new Map());
    }
    this.readingsByDeviceIdAndTimestamp.get(deviceId).set(reading.timestamp.getTime(), reading);

    this.nextReadingId++;
    this.updateDeviceCacheForReading(reading);
    return reading;
  }


  updateDeviceCacheForReading(reading) {
    const cache = this.deviceCache.get(reading.deviceId);
    if (!cache) return;

    cache.totalCount += reading.count;

    if (cache.latestTimestamp === null || reading.timestamp > cache.latestTimestamp) {
      cache.latestTimestamp = reading.timestamp;
    }
  }


  getDeviceTotalCount(deviceId) {
    const cache = this.deviceCache.get(deviceId);
    return cache ? cache.totalCount : 0;
  }


  getDeviceLatestTimestamp(deviceId) {
    const cache = this.deviceCache.get(deviceId);
    return cache ? cache.latestTimestamp : null;
  }


  findReadingByDeviceAndTimestamp(deviceId, timestamp) {
    const deviceReadings = this.readingsByDeviceIdAndTimestamp.get(deviceId);
    if (!deviceReadings) return null;
    return deviceReadings.get(timestamp.getTime()) || null;
  }

}


// Singleton instance
const storage = new Storage();

module.exports = storage;
