# Sample Project

A simple API for storing and retrieving device readings.

## Setup

```bash
bin/setup
```

*Prerequisites:*
- MacOS (or other POSIX-compliant OS)
- Ruby (any version)

## Start API Server

```bash
bin/dev
```

Press Ctrl+C to stop the server.

## Run Tests

```bash
bin/test
```

## Project Structure

- `ruby_api/` - Ruby implementation of the API
- `storage/` - In-memory data storage classes
- `tests/` - Test suite for the API implementation
- `bin/` - Development and testing scripts


## API Documentation

### Store Device Readings

Store readings from a device. Duplicate readings (same timestamp) are ignored.

```
POST /readings
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | UUID identifying the device |
| readings | array | Yes | Array of reading objects |
| readings[].timestamp | string | Yes | ISO-8601 formatted timestamp |
| readings[].count | integer | Yes | Reading count value (must be non-negative) |

**Example Request:**

```bash
curl -X POST http://localhost:3000/readings \
  -H "Content-Type: application/json" \
  -d '{
    "id": "36d5658a-6908-479e-887e-a949ec199272",
    "readings": [
      { "timestamp": "2021-09-29T16:08:15+01:00", "count": 2 },
      { "timestamp": "2021-09-29T16:09:15+01:00", "count": 15 }
    ]
  }'
```

**Responses:**

- `200 OK` - Readings stored successfully
- `400 Bad Request` - Missing or invalid parameters

> **Note:** The spec did not clearly define the behavior when the `readings` array is empty. Currently, the API will still create the device, but the device will have a `total_count = 0` and a `latest_timestamp = null` until readings are added.


### Get Latest Timestamp

Returns the timestamp of the most recent reading for a device.

```
GET /devices/:id/latest_timestamp
```

**URL Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | UUID of the device |

**Example Request:**

```bash
curl http://localhost:3000/devices/36d5658a-6908-479e-887e-a949ec199272/latest_timestamp
```

**Example Response:**

```json
{
  "latest_timestamp": "2021-09-29T16:09:15Z"
}
```

**Responses:**

- `200 OK` - Returns the latest timestamp (null if no readings)
- `404 Not Found` - Device not found


### Get Total Count

Returns the cumulative count across all readings for a device.

```
GET /devices/:id/total_count
```

**URL Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | UUID of the device |

**Example Request:**

```bash
curl http://localhost:3000/devices/36d5658a-6908-479e-887e-a949ec199272/total_count
```

**Example Response:**

```json
{
  "total_count": 17
}
```

**Responses:**

- `200 OK` - Returns the total count
- `404 Not Found` - Device not found

---

## Extra Credit

This project was structured to support multiple implementations of the API --
each contained within its own `*_api` folder -- to explore how the same
functionality can be achieved in different programming languages and frameworks.
