import { useCallback, useEffect, useState } from 'react'
import { MOCK_ADMIN_DATA } from '../data/mockData'
import type { ActionResult, AdminData, DoorItem, DoorPayload } from '../types/doors'
import { fetchNui } from '../utils/fetchNui'
import { isEnvBrowser } from '../utils/nui'

const EMPTY_DATA: AdminData = {
  ok: true,
  doors: [],
  activity: [],
  jobs: [],
  illegalGroups: [],
  framework: 'standalone',
  storage: 'json',
  settings: {
    pinMinLength: 4,
    pinMaxLength: 8,
    defaultDistance: 2,
    persistState: true,
    lockpick: true,
    sxIllegals: false,
    anyGroupGrade: 999,
  },
}

function normalizeDoor(door: DoorItem): DoorItem {
  const access = door.access ?? { jobs: {}, groups: {}, aces: [], identifiers: [], items: [] }
  return {
    ...door,
    entities: door.entities ?? [],
    access: {
      jobs: Array.isArray(access.jobs) ? {} : access.jobs ?? {},
      groups: Array.isArray(access.groups) ? {} : access.groups ?? {},
      aces: access.aces ?? [],
      identifiers: access.identifiers ?? [],
      items: access.items ?? [],
    },
  }
}

function normalizeData(data: AdminData): AdminData {
  return {
    ...EMPTY_DATA,
    ...data,
    doors: (data.doors ?? []).map(normalizeDoor),
    activity: data.activity ?? [],
    jobs: data.jobs ?? [],
    illegalGroups: data.illegalGroups ?? [],
    settings: { ...EMPTY_DATA.settings, ...data.settings },
  }
}

async function callNui(event: string, data?: unknown): Promise<ActionResult> {
  try {
    return (await fetchNui<ActionResult>(event, data)) ?? { ok: false, error: 'timeout' }
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'unknown' }
  }
}

export function useAdminData() {
  const [data, setData] = useState<AdminData>(isEnvBrowser() ? MOCK_ADMIN_DATA : EMPTY_DATA)
  const [loading, setLoading] = useState(false)

  const refresh = useCallback(async () => {
    if (isEnvBrowser()) return

    setLoading(true)
    try {
      const result = await fetchNui<AdminData>('getAdminData')
      if (result && result.ok) setData(normalizeData(result))
    } catch (err) {
      console.error('Failed to fetch admin data:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
    const interval = window.setInterval(() => void refresh(), 15_000)
    return () => window.clearInterval(interval)
  }, [refresh])

  const upsertLocal = useCallback((door: DoorItem) => {
    const normalized = normalizeDoor(door)
    setData((prev) => {
      const exists = prev.doors.some((d) => d.id === normalized.id)
      return {
        ...prev,
        doors: exists ? prev.doors.map((d) => (d.id === normalized.id ? normalized : d)) : [...prev.doors, normalized],
      }
    })
  }, [])

  const createDoor = useCallback(async (payload: DoorPayload): Promise<ActionResult> => {
    if (isEnvBrowser()) {
      const now = Math.floor(Date.now() / 1000)
      const door: DoorItem = {
        ...payload,
        id: `DOOR-${Math.random().toString(36).slice(2, 8).toUpperCase()}`,
        locked: payload.defaultLocked,
        hasPin: payload.pin !== '',
        uses: 0,
        createdAt: now,
        updatedAt: now,
      }
      upsertLocal(door)
      return { ok: true, door }
    }

    const result = await callNui('createDoor', payload)
    if (result?.ok && result.door) upsertLocal(result.door)
    return result
  }, [upsertLocal])

  const updateDoor = useCallback(async (id: string, payload: DoorPayload): Promise<ActionResult> => {
    if (isEnvBrowser()) {
      const current = data.doors.find((d) => d.id === id)
      if (!current) return { ok: false, error: 'not_found' }
      const door = { ...current, ...payload, id, hasPin: payload.pin !== '', updatedAt: Math.floor(Date.now() / 1000) }
      upsertLocal(door)
      return { ok: true, door }
    }

    const result = await callNui('updateDoor', { ...payload, id })
    if (result?.ok && result.door) upsertLocal(result.door)
    return result
  }, [data.doors, upsertLocal])

  const deleteDoor = useCallback(async (id: string): Promise<ActionResult> => {
    const result = isEnvBrowser() ? { ok: true } : await callNui('deleteDoor', { id })
    if (result?.ok) {
      setData((prev) => ({ ...prev, doors: prev.doors.filter((d) => d.id !== id) }))
    }
    return result
  }, [])

  const setDoorState = useCallback(async (id: string, locked: boolean): Promise<ActionResult> => {
    const result = isEnvBrowser() ? { ok: true, locked } : await callNui('setDoorState', { id, locked })
    if (result?.ok) {
      setData((prev) => ({
        ...prev,
        doors: prev.doors.map((d) => (d.id === id ? { ...d, locked: result.locked ?? locked } : d)),
      }))
    }
    return result
  }, [])

  const resetStates = useCallback(async (): Promise<ActionResult> => {
    const result = isEnvBrowser() ? { ok: true } : await callNui('resetDoorStates')
    if (result?.ok) {
      setData((prev) => ({
        ...prev,
        doors: prev.doors.map((d) => ({ ...d, locked: d.defaultLocked })),
      }))
    }
    return result
  }, [])

  const teleportToDoor = useCallback((door: DoorItem) => {
    void fetchNui('teleportToDoor', { coords: door.coords })
  }, [])

  const highlightDoor = useCallback((door: DoorItem) => {
    void fetchNui('highlightDoor', { id: door.id })
  }, [])

  return {
    ...data,
    loading,
    refresh,
    createDoor,
    updateDoor,
    deleteDoor,
    setDoorState,
    resetStates,
    teleportToDoor,
    highlightDoor,
  }
}
