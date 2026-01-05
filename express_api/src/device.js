const storage = require('./storage');
const Reading = require('./reading');


class Device {

  constructor(uid) {
    this.id = null;
    this.uid = uid;
  }


  save() {
    if (!this.id) {
      if (storage.findDeviceByUid(this.uid)) {
        throw new Error(`Device with uid '${this.uid}' already exists`);
      }
      storage.addDevice(this);
    }
    return this;
  }


  getTotalCount() {
    return storage.getDeviceTotalCount(this.id);
  }


  getLatestTimestamp() {
    return storage.getDeviceLatestTimestamp(this.id);
  }


  findOrCreateReading(timestamp, count) {
    const existingReading = storage.findReadingByDeviceAndTimestamp(this.id, timestamp);
    if (existingReading) {
      return existingReading;
    }
    const reading = new Reading(this.id, timestamp, count);
    reading.save();
    return reading;
  }


  static findByUid(uid) {
    return storage.findDeviceByUid(uid);
  }


  static create(uid) {
    const device = new Device(uid);
    device.save();
    return device;
  }


  static findOrCreate(uid) {
    return storage.findDeviceByUid(uid) || Device.create(uid);
  }

}


module.exports = Device;
