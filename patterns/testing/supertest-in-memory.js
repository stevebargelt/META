/**
 * Supertest In-Memory Adapter
 *
 * Runs Supertest requests directly against an Express handler without
 * binding to a port. Useful in sandboxed environments or to speed tests.
 *
 * Usage: call patchSupertestInMemory(supertest) once before tests run.
 * Source: test-app project (2026-01)
 * Pattern: Override Supertest Test.prototype to route to in-memory handler.
 */

import http from 'node:http'
import { PassThrough } from 'node:stream'

function runInMemoryRequest(handler, { method, path, headers, body }) {
  return new Promise((resolve, reject) => {
    const reqSocket = new PassThrough()
    const req = new http.IncomingMessage(reqSocket)
    const normalizedHeaders = {}

    for (const [key, value] of Object.entries(headers || {})) {
      normalizedHeaders[key.toLowerCase()] = value
    }

    if (body && normalizedHeaders['content-length'] === undefined) {
      normalizedHeaders['content-length'] = Buffer.byteLength(body)
    }

    if (!normalizedHeaders.host) {
      normalizedHeaders.host = '127.0.0.1'
    }

    req.method = method
    req.url = path
    req.headers = normalizedHeaders
    req.socket.remoteAddress = '127.0.0.1'
    req.connection = req.socket

    if (body) {
      req.push(body)
    }
    req.push(null)

    const res = new http.ServerResponse(req)
    const resSocket = new PassThrough()
    res.assignSocket(resSocket)

    const chunks = []
    const originalWrite = res.write.bind(res)
    res.write = (chunk, encoding, cb) => {
      if (chunk) {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk, encoding))
      }
      return originalWrite(chunk, encoding, cb)
    }

    const originalEnd = res.end.bind(res)
    res.end = (chunk, encoding, cb) => {
      if (chunk) {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk, encoding))
      }
      return originalEnd(chunk, encoding, cb)
    }

    res.on('finish', () => {
      resolve({
        statusCode: res.statusCode,
        headers: res.getHeaders(),
        body: Buffer.concat(chunks),
      })
    })

    try {
      handler(req, res)
    } catch (err) {
      reject(err)
    }
  })
}

export function patchSupertestInMemory(supertest) {
  const { Test } = supertest
  if (Test.prototype.__inMemoryPatched) return

  Test.prototype.__inMemoryPatched = true
  Test.prototype.serverAddress = function serverAddress(_app, path) {
    return `http://127.0.0.1${path}`
  }

  Test.prototype.end = function end(fn) {
    this._endCalled = true
    const done = fn || (() => {})
    const server = this.app
    const handler = typeof server === 'function'
      ? server
      : server.listeners('request')[0]

    const url = new URL(this.url)
    const path = `${url.pathname}${url.search}`
    const headers = { ...(this._header || {}) }

    let body = null
    if (this._data !== undefined && this._data !== null) {
      if (Buffer.isBuffer(this._data)) {
        body = this._data
      } else if (typeof this._data === 'string') {
        body = Buffer.from(this._data)
      } else {
        body = Buffer.from(JSON.stringify(this._data))
        if (!headers['content-type']) {
          headers['content-type'] = 'application/json'
        }
      }
    }

    runInMemoryRequest(handler, { method: this.method, path, headers, body })
      .then(({ statusCode, headers: resHeaders, body: resBody }) => {
        const text = resBody.length ? resBody.toString('utf8') : ''
        const contentType = String(resHeaders['content-type'] || '')
        let parsedBody = text

        if (contentType.includes('application/json')) {
          parsedBody = text ? JSON.parse(text) : {}
        }

        const res = {
          status: statusCode,
          statusCode,
          headers: resHeaders,
          text,
          body: parsedBody,
        }

        this.assert(null, res, done)
      })
      .catch((error) => {
        this.assert(error, null, done)
      })

    return this
  }
}

/*
Example:

import { describe, it, expect } from 'vitest'
import supertest from 'supertest'
import { patchSupertestInMemory } from './test-utils/supertest-in-memory.js'
import { app } from '../src/app.js'

patchSupertestInMemory(supertest)

describe('health', () => {
  it('returns ok', async () => {
    const res = await supertest(app).get('/api/health')
    expect(res.status).toBe(200)
  })
})
*/
