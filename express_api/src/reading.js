const storage = require('./storage');


class Reading {

  constructor(deviceId, timestamp, count) {
    this.id = null;
    this.deviceId = deviceId;
    this.timestamp = timestamp instanceof Date ? timestamp : new Date(timestamp);
    this.count = parseInt(count, 10);
  }


  save() {
    if (!this.id) {
      storage.addReading(this);
    }
    return this;
  }

}


module.exports = Reading;
