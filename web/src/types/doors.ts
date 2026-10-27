export type AdminCategory = 'overview' | 'doors' | 'activity'

export type DoorType = 'single' | 'double' | 'sliding' | 'garage'

export interface Vec3 {
  x: number
  y: number
  z: number
}

export interface DoorEntity {
  model: number | string
  coords: Vec3
  heading: number
}

export interface DoorAccess {
  jobs: Record<string, number>
  groups: Record<string, number>
  aces: string[]
  identifiers: string[]
  items: string[]
}

export interface DoorItem {
  id: string
  label: string
  type: DoorType
  entities: DoorEntity[]
  coords: Vec3
  distance: number
  locked: boolean
  defaultLocked: boolean
  autoLock: number
  lockpick: boolean
  hidePrompt: boolean
  pin?: string
  hasPin: boolean
  access: DoorAccess
  uses: number
  lastUse?: { time: number; player: string }
  createdAt: number
  updatedAt: number
}

export type DoorPayload = Omit<DoorItem, 'id' | 'locked' | 'hasPin' | 'uses' | 'lastUse' | 'createdAt' | 'updatedAt' | 'pin'> & {
  id?: string
  pin: string
}

export type ActivityType = 'lock' | 'unlock' | 'create' | 'update' | 'delete' | 'lockpick' | 'pin_failed' | 'denied'

export interface ActivityEntry {
  id: number
  time: number
  type: ActivityType
  severity: 'info' | 'success' | 'warning'
  doorId: string
  doorLabel: string
  player?: string
  playerId?: number
  identifier?: string
}

export interface JobGrade {
  grade: number
  label: string
}

export interface JobItem {
  name: string
  label: string
  grades: JobGrade[]
}

export interface IllegalGroup {
  id: string
  name: string
  color: string
  ranks: JobGrade[]
}

export interface AdminSettings {
  pinMinLength: number
  pinMaxLength: number
  defaultDistance: number
  persistState: boolean
  lockpick: boolean
  sxIllegals: boolean
  anyGroupGrade: number
}

export interface AdminData {
  ok: boolean
  error?: string
  doors: DoorItem[]
  activity: ActivityEntry[]
  jobs: JobItem[]
  illegalGroups: IllegalGroup[]
  framework: 'esx' | 'standalone'
  storage: 'mysql' | 'json'
  settings: AdminSettings
}

export interface ActionResult {
  ok: boolean
  error?: string
  door?: DoorItem
  locked?: boolean
  count?: number
}

export interface PickerResult {
  cancelled?: boolean
  entities?: DoorEntity[]
  coords?: Vec3
}

export interface KeypadData {
  doorId: string
  label: string
  locked: boolean
  minLength: number
  maxLength: number
}

export interface PinResult {
  ok: boolean
  reason?: string
  attemptsLeft?: number
  locked?: boolean
}
