# JWT Refresh Token Rotation

**What:** JWT authentication with rotating refresh tokens for enhanced security
**When to use:** APIs requiring authentication with long-lived sessions
**Source:** Example pattern (proven approach, adapt for your stack)

## Overview

Implements JWT-based authentication with:
- Short-lived access tokens (15 minutes)
- Long-lived refresh tokens (7 days)
- Automatic rotation on refresh (prevents replay attacks)
- Token revocation support

## Database Schema

```sql
-- Users table (simplified)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Refresh tokens table
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(500) UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),

  -- Index for quick lookups
  INDEX idx_refresh_token (token),
  INDEX idx_user_active (user_id, expires_at)
    WHERE used_at IS NULL AND revoked_at IS NULL
);
```

## Token Generation

```javascript
const jwt = require('jsonwebtoken')
const crypto = require('crypto')

// Environment variables
const ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET
const ACCESS_TOKEN_EXPIRY = '15m'
const REFRESH_TOKEN_EXPIRY = '7d'

function generateAccessToken(userId) {
  return jwt.sign(
    { userId, type: 'access' },
    ACCESS_TOKEN_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  )
}

function generateRefreshToken() {
  // Use crypto for refresh token (not JWT)
  return crypto.randomBytes(64).toString('hex')
}

async function createRefreshToken(userId) {
  const token = generateRefreshToken()
  const expiresAt = new Date()
  expiresAt.setDate(expiresAt.getDate() + 7) // 7 days

  await db.refreshTokens.create({
    userId,
    token,
    expiresAt
  })

  return token
}
```

## Login Flow

```javascript
async function login(email, password) {
  // 1. Verify credentials
  const user = await db.users.findByEmail(email)
  if (!user || !(await verifyPassword(password, user.passwordHash))) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Invalid email or password')
  }

  // 2. Generate tokens
  const accessToken = generateAccessToken(user.id)
  const refreshToken = await createRefreshToken(user.id)

  // 3. Return both tokens
  return {
    accessToken,
    refreshToken,
    expiresIn: 900 // 15 minutes in seconds
  }
}
```

## Refresh Flow (with Rotation)

```javascript
async function refreshAccessToken(oldRefreshToken) {
  // 1. Look up refresh token
  const tokenRecord = await db.refreshTokens.findByToken(oldRefreshToken)

  if (!tokenRecord) {
    throw new ApiError(401, 'INVALID_TOKEN', 'Invalid refresh token')
  }

  // 2. Check if already used (possible replay attack)
  if (tokenRecord.usedAt) {
    // Revoke all tokens for this user (security measure)
    await db.refreshTokens.revokeAllForUser(tokenRecord.userId)
    throw new ApiError(401, 'TOKEN_REUSED', 'Refresh token already used')
  }

  // 3. Check if revoked
  if (tokenRecord.revokedAt) {
    throw new ApiError(401, 'TOKEN_REVOKED', 'Refresh token revoked')
  }

  // 4. Check if expired
  if (new Date() > tokenRecord.expiresAt) {
    throw new ApiError(401, 'TOKEN_EXPIRED', 'Refresh token expired')
  }

  // 5. Mark old token as used
  await db.refreshTokens.markAsUsed(tokenRecord.id)

  // 6. Generate new tokens
  const newAccessToken = generateAccessToken(tokenRecord.userId)
  const newRefreshToken = await createRefreshToken(tokenRecord.userId)

  // 7. Return new tokens
  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
    expiresIn: 900
  }
}
```

## Auth Middleware

```javascript
function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new ApiError(401, 'NO_TOKEN', 'No token provided'))
  }

  const token = authHeader.substring(7) // Remove 'Bearer '

  try {
    const payload = jwt.verify(token, ACCESS_TOKEN_SECRET)

    if (payload.type !== 'access') {
      return next(new ApiError(401, 'INVALID_TOKEN_TYPE', 'Invalid token type'))
    }

    req.userId = payload.userId
    next()
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new ApiError(401, 'TOKEN_EXPIRED', 'Token expired'))
    }
    return next(new ApiError(401, 'INVALID_TOKEN', 'Invalid token'))
  }
}
```

## Logout

```javascript
async function logout(refreshToken) {
  const tokenRecord = await db.refreshTokens.findByToken(refreshToken)

  if (tokenRecord) {
    await db.refreshTokens.revoke(tokenRecord.id)
  }

  // Note: Access tokens remain valid until expiry (can't revoke JWT)
  // For immediate revocation, need token blacklist or shorter expiry
}
```

## API Routes Example

```javascript
// POST /auth/login
app.post('/auth/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body
  const tokens = await login(email, password)
  res.json({ data: tokens })
}))

// POST /auth/refresh
app.post('/auth/refresh', asyncHandler(async (req, res) => {
  const { refreshToken } = req.body
  const tokens = await refreshAccessToken(refreshToken)
  res.json({ data: tokens })
}))

// POST /auth/logout
app.post('/auth/logout', asyncHandler(async (req, res) => {
  const { refreshToken } = req.body
  await logout(refreshToken)
  res.json({ message: 'Logged out successfully' })
}))

// Protected route example
app.get('/profile', requireAuth, asyncHandler(async (req, res) => {
  const user = await db.users.findById(req.userId)
  res.json({ data: user })
}))
```

## Client-Side Usage

```javascript
// Store tokens (use httpOnly cookies in production for refresh token)
localStorage.setItem('accessToken', tokens.accessToken)
localStorage.setItem('refreshToken', tokens.refreshToken)

// API request with auto-refresh
async function apiRequest(url, options = {}) {
  let accessToken = localStorage.getItem('accessToken')

  // Try request with current token
  let response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${accessToken}`
    }
  })

  // If token expired, refresh and retry
  if (response.status === 401) {
    const refreshToken = localStorage.getItem('refreshToken')
    const refreshResponse = await fetch('/auth/refresh', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken })
    })

    if (refreshResponse.ok) {
      const { data } = await refreshResponse.json()
      localStorage.setItem('accessToken', data.accessToken)
      localStorage.setItem('refreshToken', data.refreshToken)

      // Retry original request
      response = await fetch(url, {
        ...options,
        headers: {
          ...options.headers,
          'Authorization': `Bearer ${data.accessToken}`
        }
      })
    } else {
      // Refresh failed, redirect to login
      window.location.href = '/login'
    }
  }

  return response
}
```

## Security Considerations

1. **Token Storage**
   - Store refresh tokens in httpOnly cookies (prevents XSS)
   - Access tokens can be in memory or localStorage
   - Never store tokens in plain cookies accessible to JavaScript

2. **HTTPS Only**
   - Always use HTTPS in production
   - Tokens in transit must be encrypted

3. **Token Rotation**
   - Rotate refresh token on every use
   - Detect and prevent replay attacks
   - Revoke all tokens if reuse detected

4. **Expiry Times**
   - Access tokens: Short (5-15 minutes)
   - Refresh tokens: Moderate (7 days)
   - Adjust based on security requirements

5. **Cleanup**
   - Regularly delete expired refresh tokens
   - Implement token pruning job

## Variations

### Using Redis Instead of Database

```javascript
// Store refresh tokens in Redis
async function createRefreshToken(userId) {
  const token = generateRefreshToken()
  const key = `refresh:${token}`

  await redis.setex(key, 7 * 24 * 60 * 60, userId) // 7 days
  return token
}
```

### Immediate Access Token Revocation

Add token blacklist (requires Redis or fast lookup):

```javascript
async function revokeAccessToken(token) {
  const decoded = jwt.decode(token)
  const expiresIn = decoded.exp - Math.floor(Date.now() / 1000)

  await redis.setex(`blacklist:${token}`, expiresIn, '1')
}

// Check in middleware
function requireAuth(req, res, next) {
  // ... verify token ...

  const isBlacklisted = await redis.exists(`blacklist:${token}`)
  if (isBlacklisted) {
    return next(new ApiError(401, 'TOKEN_REVOKED', 'Token revoked'))
  }

  // ... continue ...
}
```

## Testing

```javascript
// Test token rotation prevents reuse
test('refresh token cannot be reused', async () => {
  const { refreshToken } = await login('user@example.com', 'password')

  // First refresh works
  const tokens1 = await refreshAccessToken(refreshToken)
  expect(tokens1.accessToken).toBeDefined()

  // Second refresh with same token fails
  await expect(refreshAccessToken(refreshToken))
    .rejects.toThrow('TOKEN_REUSED')

  // All user tokens should be revoked
  const tokenCount = await db.refreshTokens.countActiveForUser(userId)
  expect(tokenCount).toBe(0)
})
```
