/**
 * Zod Validation Middleware (Express)
 *
 * Validates req.body/query/params against a Zod schema and returns
 * a structured 400 error with field-level details on failure.
 *
 * Usage: router.post('/route', validate(schema), handler)
 * Source: test-app project (2026-01)
 * Pattern: Use Zod safeParse + ApiError to normalize validation failures.
 */

// Adjust imports to your project's structure.
import { ApiError } from '../middleware/errorHandler.js'

const LOCATION_LABELS = {
  body: 'body',
  query: 'query parameters',
  params: 'route parameters',
}

export function validate(schema, location = 'body') {
  const target = LOCATION_LABELS[location] ? location : 'body'

  return (req, _res, next) => {
    const value = req[target] ?? {}
    const result = schema.safeParse(value)

    if (!result.success) {
      const fieldErrors = result.error.issues.map((issue) => ({
        field: issue.path.join('.'),
        message: issue.message,
      }))

      return next(
        new ApiError(400, 'VALIDATION_ERROR', `Invalid request ${LOCATION_LABELS[target]}`, {
          errors: fieldErrors,
        })
      )
    }

    if (target === 'query') {
      req.validatedQuery = result.data
    } else {
      req[target] = result.data
    }
    next()
  }
}

/*
Example:

import { z } from 'zod'
import { validate } from './middleware/validate.js'

const createTaskSchema = z.object({
  title: z.string().min(1),
  status: z.enum(['open', 'completed']).optional(),
})

router.post('/tasks', validate(createTaskSchema), createTask)
*/
