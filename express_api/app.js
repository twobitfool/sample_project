const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware for JSON parsing
app.use(express.json());

// Health check endpoint
app.get('/ping', (req, res) => {
  res.json({ message: 'Hello world!', status: 'ok' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Express API server listening on port ${PORT}`);
});
