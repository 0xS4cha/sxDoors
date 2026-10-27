import { useMemo, useState } from 'react'
import { History, KeyRound, Lock, LockOpen, Pencil, Plus, Search, ShieldAlert, Trash2, Wrench } from 'lucide-react'
import { EmptyState } from '../../../components/ui'
import { useTranslation } from '../../../hooks/useTranslation'
import type { ActivityEntry, ActivityType } from '../../../types/doors'
import { describeActivity, formatRelativeTime } from '../../../utils/format'

const ACTIVITY_ICONS: Record<ActivityType, typeof Lock> = {
  lock: Lock,
  unlock: LockOpen,
  create: Plus,
  update: Pencil,
  delete: Trash2,
  lockpick: Wrench,
  pin_failed: KeyRound,
  denied: ShieldAlert,
}

const SEVERITY_STYLES: Record<ActivityEntry['severity'], string> = {
  info: 'border-zinc-700 bg-zinc-900 text-zinc-300',
  success: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400',
  warning: 'border-amber-500/30 bg-amber-500/10 text-amber-400',
}

type ActivityFilter = 'all' | 'access' | 'admin' | 'security'

const FILTER_TYPES: Record<ActivityFilter, ActivityType[] | null> = {
  all: null,
  access: ['lock', 'unlock'],
  admin: ['create', 'update', 'delete'],
  security: ['lockpick', 'pin_failed', 'denied'],
}

export function ActivityList({ entries, compact = false }: { entries: ActivityEntry[]; compact?: boolean }) {
  const { t } = useTranslation()

  if (entries.length === 0) {
    return <p className="py-6 text-center text-xs text-zinc-500">{t('activity_empty')}</p>
  }

  return (
    <div className={compact ? 'space-y-3.5' : 'space-y-2'}>
      {entries.map((entry) => {
        const Icon = ACTIVITY_ICONS[entry.type] ?? History
        return (
          <div key={entry.id} className={`flex items-start gap-3 ${compact ? '' : 'rounded-lg border border-zinc-800/50 bg-zinc-950/60 px-4 py-3'}`}>
            <div className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-md border ${SEVERITY_STYLES[entry.severity]}`}>
              <Icon className="h-3.5 w-3.5" />
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-start justify-between gap-2">
                <p className="text-xs leading-relaxed text-zinc-200">{describeActivity(entry, t)}</p>
                <span className="shrink-0 text-[10px] text-zinc-500">{formatRelativeTime(entry.time, t)}</span>
              </div>
              {!compact && (
                <p className="mt-0.5 truncate font-mono text-[10px] text-zinc-500">
                  {entry.doorId}
                  {entry.identifier && ` · ${entry.identifier}`}
                  {entry.playerId !== undefined && ` · ID ${entry.playerId}`}
                </p>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

export function ActivityView({ activity }: { activity: ActivityEntry[] }) {
  const { t } = useTranslation()
  const [filter, setFilter] = useState<ActivityFilter>('all')
  const [search, setSearch] = useState('')

  const filtered = useMemo(() => {
    const types = FILTER_TYPES[filter]
    const query = search.trim().toLowerCase()
    return activity.filter((entry) => {
      if (types && !types.includes(entry.type)) return false
      if (!query) return true
      return (
        entry.doorLabel.toLowerCase().includes(query) ||
        entry.doorId.toLowerCase().includes(query) ||
        (entry.player ?? '').toLowerCase().includes(query) ||
        (entry.identifier ?? '').toLowerCase().includes(query)
      )
    })
  }, [activity, filter, search])

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1">
          <Search className="absolute top-1/2 left-3.5 h-4 w-4 -translate-y-1/2 text-zinc-500" />
          <input
            type="text"
            placeholder={t('activity_search')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-zinc-800 bg-zinc-900/60 py-2.5 pr-4 pl-10 text-xs text-zinc-200 placeholder-zinc-500 transition focus:border-zinc-700 focus:outline-none"
          />
        </div>
        <div className="flex rounded-lg border border-zinc-800 bg-zinc-950/80 p-1">
          {(Object.keys(FILTER_TYPES) as ActivityFilter[]).map((id) => (
            <button
              key={id}
              type="button"
              onClick={() => setFilter(id)}
              className={`rounded-md px-3 py-1 text-xs font-medium transition ${filter === id ? 'bg-zinc-800 text-zinc-100 shadow-sm' : 'text-zinc-400 hover:text-zinc-200'}`}
            >
              {t(`activity_filter_${id}`)}
            </button>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <EmptyState icon={<History className="h-8 w-8" />} title={t('activity_empty')} description={t('activity_empty_desc')} />
      ) : (
        <ActivityList entries={filtered} />
      )}
    </div>
  )
}
