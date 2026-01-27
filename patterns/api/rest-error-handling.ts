/**
 * REST API Error Handling Pattern
 *
 * Consistent error response format and handling for REST APIs.
 * Provides clear error messages, appropriate status codes, and optional logging.
 *
 * Usage: Use this middleware and error classes in Express-like APIs
 * Source: Example pattern (adapt for your projects)
 * Pattern: Centralized error handling with consistent response format
 */

// Error response interface
interface ErrorResponse {
  error: {
    code: string
    message: string
    details?: any
    correlationId?: string
    timestamp: string
  }
}

// Custom error class
class ApiError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details?: any
  ) {
    super(message)
    this.name = 'ApiError'
  }

  static badRequest(message: string, details?: any): ApiError {
    return new ApiError(400, 'BAD_REQUEST', message, details)
  }

  static unauthorized(message = 'Unauthorized'): ApiError {
    return new ApiError(401, 'UNAUTHORIZED', message)
  }

  static forbidden(message = 'Forbidden'): ApiError {
    return new ApiError(403, 'FORBIDDEN', message)
  }

  static notFound(resource = 'Resource'): ApiError {
    return new ApiError(404, 'NOT_FOUND', `${resource} not found`)
  }

  static conflict(message: string): ApiError {
    return new ApiError(409, 'CONFLICT', message)
  }

  static internal(message = 'Internal server error'): ApiError {
    return new ApiError(500, 'INTERNAL_ERROR', message)
  }
}

// Error handling middleware (Express)
function errorHandler(err: any, req: any, res: any, next: any) {
  // Handle ApiError instances
  if (err instanceof ApiError) {
    const response: ErrorResponse = {
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
        correlationId: req.correlationId,
        timestamp: new Date().toISOString(),
      },
    }
    return res.status(err.statusCode).json(response)
  }

  // Handle validation errors (example: express-validator)
  if (err.name === 'ValidationError') {
    const response: ErrorResponse = {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Validation failed',
        details: err.errors,
        correlationId: req.correlationId,
        timestamp: new Date().toISOString(),
      },
    }
    return res.status(400).json(response)
  }

  // Handle unexpected errors
  console.error('Unexpected error:', err)

  const response: ErrorResponse = {
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      correlationId: req.correlationId,
      timestamp: new Date().toISOString(),
    },
  }
  return res.status(500).json(response)
}

// Async handler wrapper (prevents try-catch in every route)
function asyncHandler(fn: Function) {
  return (req: any, res: any, next: any) => {
    Promise.resolve(fn(req, res, next)).catch(next)
  }
}

/*
Example Usage:

// In your Express app setup:
import { ApiError, errorHandler, asyncHandler } from './error-handling'

// Routes
app.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await getUserById(req.params.id)

  if (!user) {
    throw ApiError.notFound('User')
  }

  res.json({ data: user })
}))

app.post('/users', asyncHandler(async (req, res) => {
  const { email } = req.body

  if (!email) {
    throw ApiError.badRequest('Email is required')
  }

  const existingUser = await findUserByEmail(email)
  if (existingUser) {
    throw ApiError.conflict('User with this email already exists')
  }

  const newUser = await createUser(req.body)
  res.status(201).json({ data: newUser })
}))

// Error handler (must be last middleware)
app.use(errorHandler)

// Response format:
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User not found",
    "correlationId": "f5f5d8b2-7b8b-4c2f-9aa1-1c1d5b26f34e",
    "timestamp": "2026-01-26T12:00:00.000Z"
  }
}
*/

export { ApiError, errorHandler, asyncHandler }
