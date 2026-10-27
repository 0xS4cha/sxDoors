import type { ActivityEntry, DoorItem, JobItem } from '../types/doors'

type Translate = (key: string, replacements?: Record<string, string | number>) => string

export function formatRelativeTime(timestamp: number, t: Translate): string {
  const diff = Math.max(0, Math.floor(Date.now() / 1000) - timestamp)
  if (diff < 60) return t('time_just_now')
  if (diff < 3600) return t('time_minutes_ago', { n: Math.floor(diff / 60) })
  if (diff < 86400) return t('time_hours_ago', { n: Math.floor(diff / 3600) })
  return t('time_days_ago', { n: Math.floor(diff / 86400) })
}

export function formatCoords(coords: { x: number; y: number; z: number }): string {
  return `${coords.x.toFixed(2)}, ${coords.y.toFixed(2)}, ${coords.z.toFixed(2)}`
}

export function describeActivity(entry: ActivityEntry, t: Translate): string {
  return t(`activity_${entry.type}`, {
    player: entry.player ?? t('activity_server'),
    door: entry.doorLabel,
  })
}

export function isRestricted(door: DoorItem): boolean {
  const { jobs, aces, identifiers, items } = door.access
  return Object.keys(jobs).length > 0 || aces.length > 0 || identifiers.length > 0 || items.length > 0 || door.hasPin
}

export function jobLabel(name: string, grade: number, jobs: JobItem[]): string {
  const job = jobs.find((j) => j.name === name)
  if (!job) return grade > 0 ? `${name} ≥ ${grade}` : name
  const gradeLabel = job.grades.find((g) => g.grade === grade)?.label
  return grade > 0 ? `${job.label} ≥ ${gradeLabel ?? grade}` : job.label
}

// CEF does not always expose navigator.clipboard
export function copyToClipboard(text: string): void {
  const area = document.createElement('textarea')
  area.value = text
  area.style.position = 'fixed'
  area.style.opacity = '0'
  document.body.appendChild(area)
  area.select()
  try {
    document.execCommand('copy')
  } finally {
    document.body.removeChild(area)
  }
}
