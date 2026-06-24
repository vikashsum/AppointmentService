const express = require('express');
const config = require('./config/env');
const db = require('./models');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const app = express();

// --------------------
// Middleware
// --------------------
app.use(express.json({ limit: config.server?.bodyLimit || '10mb' }));

// --------------------
// Health Check (IMPORTANT FOR ECS)
// --------------------
// Always expose a FIXED health endpoint for ALB
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'appointment-service',
    timestamp: new Date().toISOString()
  });
});

// Your API health (optional but keep both safe)
app.get(`${config.api.prefix}/health`, (req, res) => {
  res.json({
    status: 'success',
    service: 'appointment-service'
  });
});

// --------------------
// Routes (your other routes will go here)
// --------------------
// app.use(`${config.api.prefix}/appointments`, appointmentRoutes);

// --------------------
// 404 handler
// --------------------
app.use(notFoundHandler);

// --------------------
// Error handler
// --------------------
app.use(errorHandler);

// Export app for testing
module.exports = app;

// --------------------
// Start server (ECS SAFE VERSION)
// --------------------
if (process.env.NODE_ENV !== 'test') {
  const startServer = async () => {
    try {
      // Ensure DB does not crash container silently
      await db.sequelize.authenticate();
      console.log('✓ Database connected');

      if (config.app.nodeEnv === 'development') {
        await db.sequelize.sync({ alter: true });
      }

      // IMPORTANT: FORCE PORT COMPATIBILITY WITH ECS
      const PORT = process.env.PORT || config.app.port || 3002;

      app.listen(PORT, '0.0.0.0', () => {
        console.log(`Appointment Service running on port ${PORT}`);
      });

    } catch (error) {
      console.error('❌ Failed to start service:', error);
      process.exit(1); // IMPORTANT: ECS will restart task properly
    }
  };

  startServer();
}
