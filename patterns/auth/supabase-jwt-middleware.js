/**
 * Supabase JWT Auth Middleware
 *
 * Verifies Authorization: Bearer <token> using Supabase auth.getUser.
 * Attaches userId and userEmail to req on success, otherwise raises ApiError.
 *
 * Usage: Add to protected routes or router.use(requireSupabaseAuth).
 * Source: test-app project (2026-01)
 * Pattern: Validate bearer token via Supabase, normalize errors to 401/500.
 */

// Adjust imports to your project's structure.
import { supabase } from '../lib/supabase.js'
import { logger } from '../lib/logger.js'
import { ApiError } from '../middleware/errorHandler.js'

export async function requireSupabaseAuth(req, _res, next) {
  const authHeader = req.headers.authorization

  if (!authHeader) {
    return next(new ApiError(401, 'AUTH_MISSING', 'Authorization header is required'))
  }

  const match = authHeader.match(/^Bearer\s+(.+)$/i)
  if (!match) {
    return next(new ApiError(401, 'AUTH_INVALID_FORMAT', 'Authorization header must be: Bearer <token>'))
  }

  const token = match[1]

  try {
    const { data, error } = await supabase.auth.getUser(token)

    if (error || !data?.user) {
      logger.debug({
        correlationId: req.correlationId,
        error: error?.message || 'No user returned',
      }, 'JWT verification failed')

      return next(new ApiError(401, 'AUTH_INVALID_TOKEN', 'Invalid or expired token'))
    }

    req.userId = data.user.id
    req.userEmail = data.user.email
    next()
  } catch (err) {
    logger.error({
      correlationId: req.correlationId,
      error: err.message,
      stack: err.stack,
    }, 'Auth verification error')

    next(new ApiError(500, 'AUTH_ERROR', 'Authentication service unavailable'))
  }
}

/*
Example:

import express from 'express'
import { requireSupabaseAuth } from './middleware/requireSupabaseAuth.js'

const app = express()
app.use('/api', requireSupabaseAuth)
*/
