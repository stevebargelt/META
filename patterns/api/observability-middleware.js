/**
 * Observability Middleware for Express/Node.js APIs
 *
 * Implements correlation ID tracking, structured logging, and request metrics
 * to meet cross-cutting observability requirements.
 *
 * Usage: Add as middleware to Express app
 * Source: META base requirements (observability)
 * Pattern: Generate/propagate correlation ID, log all requests, track metrics
 */

const { v4: uuidv4 } = require('uuid')
const logger = require('./logger') // Your structured logger (winston, pino, etc.)

function parseTraceparent(traceparent) {
  if (!traceparent || typeof traceparent !== 'string') return null
  const parts = traceparent.split('-')
  if (parts.length !== 4) return null
  const traceId = parts[1]
  if (!/^[0-9a-f]{32}$/i.test(traceId)) return null
  return traceId
}

/**
 * Correlation ID Middleware
 *
 * Generates or extracts correlation ID for request tracing.
 * Sets it on request object and response header.
 */
function correlationIdMiddleware(req, res, next) {
  const traceparent = req.headers['traceparent']
  const traceId = parseTraceparent(traceparent)

  // Extract from header or generate new
  req.correlationId =
    req.headers['x-correlation-id'] ||
    req.headers['x-request-id'] ||
    traceId ||
    uuidv4()

  req.traceId = traceId || null

  // Add to response headers
  res.setHeader('X-Correlation-ID', req.correlationId)
  if (traceparent) {
    res.setHeader('traceparent', traceparent)
  }

  next()
}

/**
 * Request Logging Middleware
 *
 * Logs all incoming requests with correlation ID and context.
 * Logs response after completion.
 */
function requestLoggingMiddleware(req, res, next) {
  const startTime = Date.now()

  // Log incoming request
  logger.info('Incoming request', {
    correlationId: req.correlationId,
    traceId: req.traceId || null,
    method: req.method,
    path: req.path,
    query: req.query,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
    userId: req.userId || null, // Set by auth middleware
  })

  let logged = false
  const logResponse = () => {
    if (logged) return
    logged = true

    const duration = Date.now() - startTime
    const route =
      req.route && req.route.path ? `${req.baseUrl || ''}${req.route.path}` : req.path

    // Log response
    logger.info('Request completed', {
      correlationId: req.correlationId,
      traceId: req.traceId || null,
      method: req.method,
      path: route,
      statusCode: res.statusCode,
      duration,
      userId: req.userId || null,
    })

    // Send metrics (if metrics system configured)
    if (global.metrics) {
      global.metrics.recordRequestDuration(req.method, route, duration)
      global.metrics.incrementRequestCount(req.method, route, res.statusCode)
    }
  }

  res.on('finish', logResponse)
  res.on('close', logResponse)

  next()
}

/**
 * Error Context Middleware
 *
 * Ensures all errors include correlation ID and proper context.
 * Must be registered AFTER all routes.
 */
function errorContextMiddleware(err, req, res, next) {
  // Ensure error has correlation ID
  err.correlationId = err.correlationId || req.correlationId

  // Log error with full context
  logger.error('Request error', {
    correlationId: req.correlationId,
    error: err.message,
    stack: err.stack,
    statusCode: err.statusCode || 500,
    method: req.method,
    path: req.path,
    userId: req.userId || null,
    details: err.details || null,
  })

  // Don't expose internal errors
  const statusCode = err.statusCode || 500
  const response = {
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: err.statusCode ? err.message : 'An unexpected error occurred',
      correlationId: req.correlationId,
    }
  }

  // Include details only for client errors (4xx)
  if (err.statusCode && err.statusCode < 500 && err.details) {
    response.error.details = err.details
  }

  res.status(statusCode).json(response)
}

/**
 * Audit Logging Helper
 *
 * For state-changing operations that need audit trail.
 */
function auditLog(action, req, resource, metadata = {}) {
  logger.info('Audit log', {
    correlationId: req.correlationId,
    userId: req.userId,
    action,
    resource,
    timestamp: new Date().toISOString(),
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    metadata,
  })

  // Also send to dedicated audit log system if configured
  if (global.auditLogger) {
    global.auditLogger.record({
      correlationId: req.correlationId,
      userId: req.userId,
      action,
      resource,
      timestamp: new Date().toISOString(),
      ip: req.ip,
      metadata,
    })
  }
}

/**
 * Downstream Service Call Helper
 *
 * Ensures correlation ID is propagated to downstream services.
 */
async function callDownstream(url, options = {}) {
  const correlationId =
    options.correlationId ||
    // If called from request context, could use async_hooks to get it
    null

  const headers = {
    ...options.headers,
    'X-Correlation-ID': correlationId,
  }
  if (options.traceparent) {
    headers['traceparent'] = options.traceparent
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    })

    logger.info('Downstream call completed', {
      correlationId,
      url,
      method: options.method || 'GET',
      statusCode: response.status,
    })

    return response
  } catch (err) {
    logger.error('Downstream call failed', {
      correlationId,
      url,
      method: options.method || 'GET',
      error: err.message,
    })
    throw err
  }
}

/*
Example Usage in Express App:

const express = require('express')
const {
  correlationIdMiddleware,
  requestLoggingMiddleware,
  errorContextMiddleware,
  auditLog,
  callDownstream,
} = require('./observability-middleware')

const app = express()

// 1. Correlation ID (first!)
app.use(correlationIdMiddleware)

// 2. Request logging
app.use(requestLoggingMiddleware)

// 3. Auth middleware (sets req.userId)
app.use(authMiddleware)

// 4. Routes
app.post('/users', async (req, res) => {
  const user = await createUser(req.body)

  // Audit log for state change
  auditLog('CREATE_USER', req, `user:${user.id}`, {
    email: user.email
  })

  res.status(201).json({ data: user })
})

app.delete('/users/:id', async (req, res) => {
  await deleteUser(req.params.id)

  // Audit log for deletion
  auditLog('DELETE_USER', req, `user:${req.params.id}`, {
    reason: req.body.reason
  })

  res.status(204).send()
})

app.get('/users/:id/orders', async (req, res) => {
  // Call downstream service with correlation ID
  const response = await callDownstream(
    `${ORDER_SERVICE}/orders?userId=${req.params.id}`,
    { correlationId: req.correlationId }
  )

  const orders = await response.json()
  res.json({ data: orders })
})

// 5. Error handler (last!)
app.use(errorContextMiddleware)

// Health check endpoints
app.get('/health', (req, res) => {
  res.json({ status: 'ok' })
})

app.get('/ready', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkCache(),
  }

  const ready = Object.values(checks).every(c => c.ok)

  res.status(ready ? 200 : 503).json({
    status: ready ? 'ready' : 'not ready',
    checks,
  })
})

app.get('/version', (req, res) => {
  res.json({
    service: 'api-service',
    version: process.env.VERSION || 'unknown',
    commit: process.env.GIT_COMMIT || 'unknown',
    buildTime: process.env.BUILD_TIME || 'unknown',
  })
})

// Logger configuration (winston example)
const winston = require('winston')

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'api-service',
    version: process.env.VERSION,
  },
  transports: [
    new winston.transports.Console(),
    // Production: add file or cloud logging transport
  ],
})

// Metrics setup (example with prom-client)
const promClient = require('prom-client')

const requestDuration = new promClient.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'path', 'status_code'],
})

const requestCount = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status_code'],
})

global.metrics = {
  recordRequestDuration(method, path, duration) {
    requestDuration.labels(method, path).observe(duration)
  },
  incrementRequestCount(method, path, statusCode) {
    requestCount.labels(method, path, statusCode).inc()
  },
}

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType)
  res.end(await promClient.register.metrics())
})
*/

module.exports = {
  correlationIdMiddleware,
  requestLoggingMiddleware,
  errorContextMiddleware,
  auditLog,
  callDownstream,
}
