import { ArrowLeftRight, Columns2, DoorClosed, Warehouse } from 'lucide-react'
import type { DoorType } from '../../../types/doors'

export const DOOR_TYPES: { id: DoorType; icon: typeof DoorClosed; maxEntities: number }[] = [
  { id: 'single', icon: DoorClosed, maxEntities: 1 },
  { id: 'double', icon: Columns2, maxEntities: 2 },
  { id: 'sliding', icon: ArrowLeftRight, maxEntities: 2 },
  { id: 'garage', icon: Warehouse, maxEntities: 1 },
]

export function getDoorTypeMeta(type: DoorType) {
  return DOOR_TYPES.find((d) => d.id === type) ?? DOOR_TYPES[0]
}
