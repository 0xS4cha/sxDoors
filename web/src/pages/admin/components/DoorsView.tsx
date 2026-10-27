import { useMemo, useState } from 'react'
import { motion } from 'motion/react'
import {
  Briefcase,
  Copy,
  DoorClosed,
  Eye,
  Hash,
  KeyRound,
  Lock,
  LockOpen,
  MapPin,
  Package,
  Pencil,
  Plus,
  Search,
  ShieldCheck,
  Skull,
  Timer,
  Trash2,
  Users,
  Wrench,
} from 'lucide-react'
import { Badge, Button, EmptyState, IconButton } from '../../../components/ui'
import { useTranslation } from '../../../hooks/useTranslation'
import type { DoorItem, DoorType, IllegalGroup, JobItem } from '../../../types/doors'
import { copyToClipboard, formatRelativeTime, groupLabel, isRestricted, jobLabel } from '../../../utils/format'
import { DOOR_TYPES, getDoorTypeMeta } from './doorMeta'

type StateFilter = 'all' | 'locked' | 'unlocked' | 'restricted' | 'public' | 'pin' | 'lockpick'

interface DoorsViewProps {
  doors: DoorItem[]
  jobs: JobItem[]
  illegalGroups: IllegalGroup[]
  anyGroupGrade: number
  onCreate: () => void
  onEdit: (door: DoorItem) => void
  onDelete: (door: DoorItem) => void
  onToggleState: (door: DoorItem) => void
  onTeleport: (door: DoorItem) => void
  onHighlight: (door: DoorItem) => void
}

const FILTERS: StateFilter[] = ['all', 'locked', 'unlocked', 'restricted', 'public', 'pin', 'lockpick']

function matchesFilter(door: DoorItem, filter: StateFilter): boolean {
  switch (filter) {
    case 'locked': return door.locked
    case 'unlocked': return !door.locked
    case 'restricted': return isRestricted(door)
    case 'public': return !isRestricted(door)
    case 'pin': return door.hasPin
    case 'lockpick': return door.lockpick
    default: return true
  }
}

export function DoorsView({ doors, jobs, illegalGroups, anyGroupGrade, onCreate, onEdit, onDelete, onToggleState, onTeleport, onHighlight }: DoorsViewProps) {
  const { t } = useTranslation()
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState<StateFilter>('all')
  const [typeFilter, setTypeFilter] = useState<DoorType | 'all'>('all')
  const [copied, setCopied] = useState<string | null>(null)

  const filteredDoors = useMemo(() => {
    const query = search.trim().toLowerCase()
    return doors.filter((door) => {
      if (typeFilter !== 'all' && door.type !== typeFilter) return false
      if (!matchesFilter(door, filter)) return false
      if (!query) return true
      return (
        door.label.toLowerCase().includes(query) ||
        door.id.toLowerCase().includes(query) ||
        Object.keys(door.access.jobs).some((job) => job.toLowerCase().includes(query)) ||
        Object.keys(door.access.groups).some((id) => (illegalGroups.find((g) => g.id === id)?.name ?? id).toLowerCase().includes(query)) ||
        door.access.items.some((item) => item.toLowerCase().includes(query))
      )
    })
  }, [doors, filter, illegalGroups, search, typeFilter])

  const handleCopy = (id: string) => {
    copyToClipboard(id)
    setCopied(id)
    window.setTimeout(() => setCopied((prev) => (prev === id ? null : prev)), 1500)
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
        <div className="relative flex-1">
          <Search className="absolute top-1/2 left-3.5 h-4 w-4 -translate-y-1/2 text-zinc-500" />
          <input
            type="text"
            placeholder={t('doors_search')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-zinc-800 bg-zinc-900/60 py-2.5 pr-4 pl-10 text-xs text-zinc-200 placeholder-zinc-500 transition focus:border-zinc-700 focus:outline-none"
          />
        </div>

        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value as DoorType | 'all')}
          className="rounded-lg border border-zinc-800 bg-zinc-900/60 px-3 py-2.5 text-xs text-zinc-200 focus:border-zinc-700 focus:outline-none"
        >
          <option value="all">{t('doors_type_all')}</option>
          {DOOR_TYPES.map((type) => (
            <option key={type.id} value={type.id}>{t(`door_type_${type.id}`)}</option>
          ))}
        </select>

        <Button variant="primary" icon={<Plus className="h-4 w-4" />} onClick={onCreate} className="py-2.5">
          {t('doors_create')}
        </Button>
      </div>

      <div className="flex flex-wrap gap-1 rounded-lg border border-zinc-800 bg-zinc-950/80 p-1">
        {FILTERS.map((id) => (
          <button
            key={id}
            type="button"
            onClick={() => setFilter(id)}
            className={`rounded-md px-3 py-1 text-xs font-medium transition ${filter === id ? 'bg-zinc-800 text-zinc-100 shadow-sm' : 'text-zinc-400 hover:text-zinc-200'}`}
          >
            {t(`doors_filter_${id}`)} ({doors.filter((door) => matchesFilter(door, id)).length})
          </button>
        ))}
      </div>

      {filteredDoors.length === 0 ? (
        <EmptyState
          icon={<DoorClosed className="h-8 w-8" />}
          title={t('doors_empty_title')}
          description={t('doors_empty_desc')}
          action={<Button icon={<Plus className="h-3.5 w-3.5" />} onClick={onCreate}>{t('doors_create')}</Button>}
        />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {filteredDoors.map((door, index) => {
            const TypeIcon = getDoorTypeMeta(door.type).icon
            const jobEntries = Object.entries(door.access.jobs)

            return (
              <motion.div
                key={door.id}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: Math.min(index * 0.03, 0.3) }}
                className="group relative overflow-hidden rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-4 transition hover:border-zinc-700 hover:bg-zinc-900/60"
              >
                <div className={`absolute inset-x-0 top-0 h-[2px] ${door.locked ? 'bg-rose-500/60' : 'bg-emerald-500/60'}`} />

                <div className="flex items-start justify-between gap-3">
                  <div className="flex min-w-0 items-start gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-950 text-zinc-300">
                      <TypeIcon className="h-4 w-4" />
                    </div>
                    <div className="min-w-0">
                      <h4 className="truncate text-sm font-bold text-zinc-100">{door.label}</h4>
                      <button
                        type="button"
                        onClick={() => handleCopy(door.id)}
                        className="mt-0.5 flex items-center gap-1 font-mono text-[11px] text-zinc-500 transition hover:text-zinc-300"
                        title={t('doors_copy_id')}
                      >
                        <Hash className="h-3 w-3" />
                        {copied === door.id ? t('doors_copied') : door.id}
                        <Copy className="h-3 w-3 opacity-0 transition group-hover:opacity-100" />
                      </button>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => onToggleState(door)}
                    className={`flex shrink-0 items-center gap-1.5 rounded-full border px-2.5 py-1 text-[11px] font-bold transition ${door.locked ? 'border-rose-500/30 bg-rose-500/10 text-rose-400 hover:bg-rose-500/20' : 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20'}`}
                    title={door.locked ? t('doors_action_unlock') : t('doors_action_lock')}
                  >
                    {door.locked ? <Lock className="h-3 w-3" /> : <LockOpen className="h-3 w-3" />}
                    {door.locked ? t('state_locked') : t('state_unlocked')}
                  </button>
                </div>

                <div className="mt-3 flex min-h-[22px] flex-wrap gap-1.5">
                  <Badge>{t(`door_type_${door.type}`)}</Badge>
                  {!isRestricted(door) && <Badge tone="success" icon={<Users className="h-3 w-3" />}>{t('access_public')}</Badge>}
                  {jobEntries.map(([name, grade]) => (
                    <Badge key={name} tone="info" icon={<Briefcase className="h-3 w-3" />}>{jobLabel(name, grade, jobs)}</Badge>
                  ))}
                  {Object.entries(door.access.groups).map(([id, grade]) => (
                    <Badge key={id} tone="danger" icon={<Skull className="h-3 w-3" />}>{groupLabel(id, grade, illegalGroups, anyGroupGrade)}</Badge>
                  ))}
                  {door.access.items.map((item) => (
                    <Badge key={item} tone="violet" icon={<Package className="h-3 w-3" />}>{item}</Badge>
                  ))}
                  {door.access.aces.length > 0 && (
                    <Badge tone="neutral" icon={<ShieldCheck className="h-3 w-3" />} title={door.access.aces.join(', ')}>
                      {t('access_aces_count', { n: door.access.aces.length })}
                    </Badge>
                  )}
                  {door.access.identifiers.length > 0 && (
                    <Badge tone="neutral" icon={<Users className="h-3 w-3" />}>
                      {t('access_identifiers_count', { n: door.access.identifiers.length })}
                    </Badge>
                  )}
                  {door.hasPin && <Badge tone="warning" icon={<KeyRound className="h-3 w-3" />}>{t('access_pin')}</Badge>}
                  {door.lockpick && <Badge tone="danger" icon={<Wrench className="h-3 w-3" />}>{t('access_lockpick')}</Badge>}
                  {door.autoLock > 0 && <Badge icon={<Timer className="h-3 w-3" />}>{t('access_autolock', { n: door.autoLock })}</Badge>}
                </div>

                <div className="mt-3 flex items-center justify-between border-t border-zinc-800/60 pt-3">
                  <p className="truncate text-[11px] text-zinc-500">
                    {door.lastUse
                      ? t('doors_last_use', { player: door.lastUse.player, time: formatRelativeTime(door.lastUse.time, t) })
                      : t('doors_never_used')}
                  </p>
                  <div className="flex shrink-0 items-center gap-0.5">
                    <IconButton onClick={() => onHighlight(door)} title={t('doors_action_highlight')}><Eye className="h-3.5 w-3.5" /></IconButton>
                    <IconButton onClick={() => onTeleport(door)} title={t('doors_action_teleport')}><MapPin className="h-3.5 w-3.5" /></IconButton>
                    <IconButton onClick={() => onEdit(door)} title={t('doors_action_edit')}><Pencil className="h-3.5 w-3.5" /></IconButton>
                    <IconButton onClick={() => onDelete(door)} title={t('doors_action_delete')} className="hover:bg-rose-500/10 hover:text-rose-400">
                      <Trash2 className="h-3.5 w-3.5" />
                    </IconButton>
                  </div>
                </div>
              </motion.div>
            )
          })}
        </div>
      )}
    </div>
  )
}
