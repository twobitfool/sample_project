const express = require('express');
const Device = require('./src/device');

const app = express();
const PORT = process.env.PORT || 3000;


// Middleware for JSON parsing with error handling for malformed JSON
app.use((req, res, next) => {
  express.json()(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: 'Malformed JSON payload' });
    }
    next();
  });
});


// Health check endpoint
app.get('/ping', (req, res) => {
  res.json({ message: 'Hello world!', status: 'ok' });
});


// Store readings for a device
app.post('/readings', (req, res) => {
  const deviceUid = req.body.id;
  const readingsData = req.body.readings;

  // Validate id
  if (deviceUid === undefined || deviceUid === null || deviceUid === '') {
    return res.status(400).json({ error: 'id is required' });
  }

  // Validate readings array
  if (readingsData === undefined || readingsData === null || !Array.isArray(readingsData)) {
    return res.status(400).json({ error: 'readings array is required' });
  }

  // Validate each reading
  const validationError = validateReadings(readingsData);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  // Find or create device
  const device = Device.findOrCreate(deviceUid);

  // Process each reading
  for (const reading of readingsData) {
    const timestamp = new Date(reading.timestamp);
    device.findOrCreateReading(timestamp, reading.count);
  }

  res.json({ success: true });
});


// Get the latest timestamp for a device
app.get('/devices/:id/latest_timestamp', (req, res) => {
  const device = Device.findByUid(req.params.id);

  if (!device) {
    return res.status(404).json({ error: 'Device not found' });
  }

  const latest = device.getLatestTimestamp();
  const formattedTimestamp = latest ? formatTimestampUTC(latest) : null;

  res.json({ latest_timestamp: formattedTimestamp });
});


// Get the total count for a device
app.get('/devices/:id/total_count', (req, res) => {
  const device = Device.findByUid(req.params.id);

  if (!device) {
    return res.status(404).json({ error: 'Device not found' });
  }

  res.json({ total_count: device.getTotalCount() });
});


// Validation helper for readings array
function validateReadings(readingsData) {
  for (const reading of readingsData) {
    const timestamp = reading.timestamp;
    const count = reading.count;

    // Validate timestamp
    if (timestamp === undefined || timestamp === null || timestamp === '') {
      return 'timestamp is required for each reading';
    }

    // Check if timestamp is valid
    const parsedDate = new Date(timestamp);
    if (isNaN(parsedDate.getTime())) {
      return `invalid timestamp: ${timestamp}`;
    }

    // Validate count exists
    if (count === undefined || count === null) {
      return 'count is required for each reading';
    }

    // Check if count is an integer
    if (!Number.isInteger(count)) {
      return `invalid count: ${count} (must be an integer)`;
    }

    // Check if count is non-negative
    if (count < 0) {
      return `invalid count: ${count} (must be non-negative)`;
    }
  }

  return null;
}


// Format timestamp as ISO-8601 UTC (e.g., "2021-09-29T17:08:15Z")
function formatTimestampUTC(date) {
  return date.toISOString().replace(/\.\d{3}Z$/, 'Z');
}


// 404 handler for unknown routes
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});


// Start the server
app.listen(PORT, () => {
  console.log(`Express API server listening on port ${PORT}`);
});
