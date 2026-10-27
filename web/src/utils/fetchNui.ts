import { getResourceName, isEnvBrowser } from './nui'
import type { NuiCallbackResponse } from '../types/nui'

const DEFAULT_TIMEOUT_MS = 10_000

export async function fetchNui<T = unknown>(
  event: string,
  data?: unknown,
  mockData?: T,
): Promise<T> {
  if (isEnvBrowser()) {
    if (mockData !== undefined) {
      return mockData
    }

    return { ok: true } as T
  }

  const controller = new AbortController()
  const timeout = window.setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS)

  try {
    const response = await fetch(`https://${getResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
      signal: controller.signal,
    })

    if (!response.ok) {
      throw new Error(`NUI callback "${event}" failed with status ${response.status}`)
    }

    const payload = (await response.json()) as NuiCallbackResponse<T> | T

    if (payload && typeof payload === 'object' && 'ok' in payload && payload.ok === false) {
      throw new Error(
        'error' in payload && typeof payload.error === 'string'
          ? payload.error
          : `NUI callback "${event}" returned an error`,
      )
    }

    if (payload && typeof payload === 'object' && 'data' in payload) {
      return payload.data as T
    }

    return payload as T
  } finally {
    window.clearTimeout(timeout)
  }
}
