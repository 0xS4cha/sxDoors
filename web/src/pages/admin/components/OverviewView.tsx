import { motion } from 'motion/react'
import { ArrowUpRight, DoorClosed, Lock, LockOpen, Plus, RotateCcw, ShieldCheck, TrendingUp, Wrench } from 'lucide-react'
import { Button } from '../../../components/ui'
import { useTranslation } from '../../../hooks/useTranslation'
import type { ActivityEntry, AdminCategory, DoorItem } from '../../../types/doors'
import { isRestricted } from '../../../utils/format'
import { ActivityList } from './ActivityView'

interface OverviewViewProps {
  doors: DoorItem[]
  activity: ActivityEntry[]
  onSelectCategory: (category: AdminCategory) => void
  onCreate: () => void
  onResetStates: () => void
  onToggleState: (door: DoorItem) => void
}

export function OverviewView({ doors, activity, onSelectCategory, onCreate, onResetStates, onToggleState }: OverviewViewProps) {
  const { t } = useTranslation()

  const lockedCount = doors.filter((d) => d.locked).length
  const restrictedCount = doors.filter(isRestricted).length
  const lockpickCount = doors.filter((d) => d.lockpick).length
  const mostUsed = [...doors].sort((a, b) => b.uses - a.uses).slice(0, 5)
  const maxUses = Math.max(1, ...mostUsed.map((d) => d.uses))

  const kpiCards = [
    { title: t('overview_total'), value: doors.length, subtitle: t('overview_total_sub', { n: doors.filter((d) => d.type === 'double').length }), icon: DoorClosed },
    { title: t('overview_locked'), value: lockedCount, subtitle: t('overview_locked_sub', { n: doors.length - lockedCount }), icon: Lock },
    { title: t('overview_restricted'), value: restrictedCount, subtitle: t('overview_restricted_sub', { n: doors.filter((d) => d.hasPin).length }), icon: ShieldCheck },
    { title: t('overview_lockpick'), value: lockpickCount, subtitle: t('overview_lockpick_sub'), icon: Wrench },
  ]

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {kpiCards.map((card, idx) => {
          const Icon = card.icon
          return (
            <motion.div
              key={card.title}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: idx * 0.05, duration: 0.2 }}
              onClick={() => onSelectCategory('doors')}
              className="group cursor-pointer rounded-xl border border-zinc-800/80 bg-zinc-900/60 p-4 transition hover:border-zinc-700 hover:bg-zinc-900"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-zinc-400">{card.title}</span>
                <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-950 text-zinc-300 transition group-hover:border-zinc-700 group-hover:text-white">
                  <Icon className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline justify-between">
                <span className="text-2xl font-bold text-zinc-100">{card.value}</span>
                <ArrowUpRight className="h-4 w-4 text-zinc-500 transition group-hover:translate-x-0.5 group-hover:-translate-y-0.5 group-hover:text-zinc-300" />
              </div>
              <p className="mt-1 text-xs text-zinc-400">{card.subtitle}</p>
            </motion.div>
          )
        })}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-5"
          >
            <div className="flex items-center justify-between border-b border-zinc-800/60 pb-4">
              <div className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4 text-zinc-300" />
                <h3 className="text-sm font-semibold text-zinc-200">{t('overview_most_used')}</h3>
              </div>
              <button type="button" onClick={() => onSelectCategory('doors')} className="text-xs text-zinc-400 transition hover:text-zinc-200">
                {t('overview_see_all', { n: doors.length })} →
              </button>
            </div>

            <div className="mt-4 space-y-2.5">
              {mostUsed.length === 0 && <p className="py-6 text-center text-xs text-zinc-500">{t('doors_empty_title')}</p>}
              {mostUsed.map((door) => (
                <div key={door.id} className="flex items-center gap-3 rounded-lg border border-zinc-800/50 bg-zinc-950/60 px-4 py-2.5">
                  <button
                    type="button"
                    onClick={() => onToggleState(door)}
                    title={door.locked ? t('doors_action_unlock') : t('doors_action_lock')}
                    className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-md border transition ${door.locked ? 'border-rose-500/30 bg-rose-500/10 text-rose-400 hover:bg-rose-500/20' : 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20'}`}
                  >
                    {door.locked ? <Lock className="h-3.5 w-3.5" /> : <LockOpen className="h-3.5 w-3.5" />}
                  </button>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <span className="truncate text-sm font-medium text-zinc-100">{door.label}</span>
                      <span className="shrink-0 text-xs text-zinc-400">{t('overview_uses', { n: door.uses })}</span>
                    </div>
                    <div className="mt-1.5 h-1 w-full overflow-hidden rounded-full bg-zinc-800">
                      <div className="h-full rounded-full bg-zinc-400 transition-all" style={{ width: `${(door.uses / maxUses) * 100}%` }} />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 }}
            className="flex flex-col gap-4 rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-5 sm:flex-row sm:items-center sm:justify-between"
          >
            <div>
              <h3 className="text-sm font-semibold text-zinc-200">{t('overview_actions')}</h3>
              <p className="mt-1 text-xs text-zinc-400">{t('overview_actions_desc')}</p>
            </div>
            <div className="flex shrink-0 gap-2">
              <Button icon={<RotateCcw className="h-3.5 w-3.5" />} onClick={onResetStates}>{t('overview_reset_states')}</Button>
              <Button variant="primary" icon={<Plus className="h-3.5 w-3.5" />} onClick={onCreate}>{t('doors_create')}</Button>
            </div>
          </motion.div>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="flex max-h-[460px] flex-col rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-5"
        >
          <div className="flex items-center justify-between border-b border-zinc-800/60 pb-4">
            <h3 className="text-sm font-semibold text-zinc-200">{t('overview_recent_activity')}</h3>
            <button type="button" onClick={() => onSelectCategory('activity')} className="text-xs text-zinc-400 transition hover:text-zinc-200">
              {t('overview_see_activity')} →
            </button>
          </div>
          <div className="mt-4 flex-1 overflow-auto pr-1">
            <ActivityList entries={activity.slice(0, 10)} compact />
          </div>
        </motion.div>
      </div>
    </div>
  )
}
