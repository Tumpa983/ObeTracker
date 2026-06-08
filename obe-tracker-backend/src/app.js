require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// ── Security & Parsing ────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    // Allow: no origin (curl/Postman), localhost ports, and file:// pages (origin = 'null')
    if (!origin || origin === 'null' || origin.includes('localhost') || origin.includes('127.0.0.1')) {
      callback(null, true);
    } else {
      const allowed = (process.env.FRONTEND_URL || '').split(',').map(s => s.trim()).filter(Boolean);
      callback(allowed.includes(origin) ? null : new Error('CORS'), allowed.includes(origin));
    }
  },
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Routes ────────────────────────────────────────────────────
app.use('/api/v1/auth',    require('./routes/auth.routes'));
app.use('/api/v1/admin',   require('./routes/admin.routes'));
app.use('/api/v1/faculty', require('./routes/faculty.routes'));
app.use('/api/v1/student', require('./routes/student.routes'));
app.use('/api/v1/reports', require('./routes/report.routes'));
app.use('/api/v1/bulk',    require('./routes/bulk.routes'));

// ── Health ────────────────────────────────────────────────────
app.get('/api/v1/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

// ── 404 ───────────────────────────────────────────────────────
app.use((req, res) => res.status(404).json({ status: 'error', error: `Route ${req.method} ${req.path} not found` }));

// ── Error Handler ─────────────────────────────────────────────
app.use(errorHandler);

module.exports = app;
