import { motion } from 'motion/react'
import { ChevronLeft, ChevronRight, DoorClosed, History, LayoutDashboard, X } from 'lucide-react'
import { useTranslation } from '../../../hooks/useTranslation'
import type { AdminCategory } from '../../../types/doors'
import { fetchNui } from '../../../utils/fetchNui'

interface AdminSidebarProps {
  activeCategory: AdminCategory
  onSelectCategory: (category: AdminCategory) => void
  doorsCount: number
  warningsCount: number
  framework: string
  storage: string
  collapsed: boolean
  onToggleCollapse: () => void
}

export function AdminSidebar({
  activeCategory,
  onSelectCategory,
  doorsCount,
  warningsCount,
  framework,
  storage,
  collapsed,
  onToggleCollapse,
}: AdminSidebarProps) {
  const { t } = useTranslation()

  const navItems = [
    { id: 'overview' as const, label: t('admin_nav_overview'), icon: LayoutDashboard },
    { id: 'doors' as const, label: t('admin_nav_doors'), icon: DoorClosed, badge: doorsCount, warn: false },
    { id: 'activity' as const, label: t('admin_nav_activity'), icon: History, badge: warningsCount > 0 ? warningsCount : undefined, warn: true },
  ]

  return (
    <aside className={`relative flex shrink-0 flex-col border-r border-zinc-800/80 bg-zinc-950/80 transition-all duration-300 ${collapsed ? 'w-20' : 'w-60'}`}>
      <div className="flex h-16 items-center justify-between border-b border-zinc-800/80 px-4">
        <div className="flex items-center gap-3 overflow-hidden">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-zinc-700/60 bg-zinc-900 shadow-sm">
            <DoorClosed className="h-5 w-5 text-zinc-200" />
          </div>
          {!collapsed && (
            <motion.div initial={{ opacity: 0, x: -6 }} animate={{ opacity: 1, x: 0 }} className="flex flex-col overflow-hidden">
              <span className="truncate text-xs font-semibold uppercase tracking-wider text-zinc-400">sxDoors</span>
              <span className="truncate text-sm font-bold text-zinc-100">{t('admin_title')}</span>
            </motion.div>
          )}
        </div>

        <button
          type="button"
          onClick={onToggleCollapse}
          className="flex h-7 w-7 items-center justify-center rounded-md text-zinc-400 transition hover:bg-zinc-800/60 hover:text-zinc-200"
        >
          {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
        </button>
      </div>

      <nav className="flex-1 space-y-1.5 p-3">
        {!collapsed && (
          <div className="mb-2 px-2">
            <span className="text-[10px] font-medium uppercase tracking-widest text-zinc-500">{t('admin_nav_section')}</span>
          </div>
        )}

        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = activeCategory === item.id

          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onSelectCategory(item.id)}
              title={collapsed ? item.label : undefined}
              className={`relative flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-200 ${isActive ? 'font-semibold text-zinc-100' : 'text-zinc-400 hover:bg-zinc-900/60 hover:text-zinc-200'}`}
            >
              {isActive && (
                <motion.div
                  layoutId="activeSidebarIndicator"
                  className="absolute inset-0 rounded-lg border border-zinc-700/80 bg-zinc-900 shadow-inner"
                  transition={{ type: 'spring', stiffness: 350, damping: 30 }}
                />
              )}
              <span className="relative z-10 flex items-center justify-center">
                <Icon className={`h-4 w-4 ${isActive ? 'text-zinc-100' : 'text-zinc-400'}`} />
              </span>
              {!collapsed && <span className="relative z-10 flex-1 truncate text-left">{item.label}</span>}
              {!collapsed && item.badge !== undefined && (
                <span
                  className={`relative z-10 rounded-full border px-2 py-0.5 text-[11px] font-semibold ${item.warn ? 'border-amber-500/20 bg-amber-500/10 text-amber-400' : 'border-zinc-700 bg-zinc-800 text-zinc-300'}`}
                >
                  {item.badge}
                </span>
              )}
            </button>
          )
        })}
      </nav>

      <div className="space-y-2 border-t border-zinc-800/80 p-3">
        {!collapsed && (
          <div className="space-y-1.5 rounded-lg border border-zinc-800/60 bg-zinc-900/40 p-2.5 text-[11px]">
            <div className="flex items-center justify-between text-zinc-400">
              <span className="flex items-center gap-1.5">
                <span className="h-2 w-2 animate-pulse rounded-full bg-emerald-500" />
                {t('admin_framework')}
              </span>
              <span className="font-mono uppercase text-zinc-300">{framework}</span>
            </div>
            <div className="flex items-center justify-between text-zinc-400">
              <span className="pl-3.5">{t('admin_storage')}</span>
              <span className="font-mono uppercase text-zinc-300">{storage}</span>
            </div>
          </div>
        )}

        <button
          type="button"
          onClick={() => void fetchNui('close')}
          className={`flex w-full items-center justify-center gap-2 rounded-lg border border-zinc-800 bg-zinc-900/80 py-2 text-xs font-medium text-zinc-300 transition hover:border-zinc-700 hover:bg-zinc-800 hover:text-white ${collapsed ? 'px-2' : 'px-3'}`}
        >
          <X className="h-4 w-4 text-zinc-400" />
          {!collapsed && <span>{t('btn_close')} (ESC)</span>}
        </button>
      </div>
    </aside>
  )
}
