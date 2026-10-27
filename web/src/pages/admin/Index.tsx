import { useEffect, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { DoorClosed, History, LayoutDashboard, Plus, RefreshCw } from 'lucide-react'
import { Button } from '../../components/ui'
import { useAdminData } from '../../hooks/useAdminData'
import { useTranslation } from '../../hooks/useTranslation'
import type { AdminCategory, DoorItem } from '../../types/doors'
import { ActivityView } from './components/ActivityView'
import { AdminSidebar } from './components/AdminSidebar'
import { ConfirmModal } from './components/ConfirmModal'
import { DoorModal } from './components/DoorModal'
import { DoorsView } from './components/DoorsView'
import { OverviewView } from './components/OverviewView'

type ModalState = { mode: 'create' } | { mode: 'edit'; door: DoorItem } | null
type ConfirmState = { kind: 'delete'; door: DoorItem } | { kind: 'reset' } | null

const HEADER_ICONS: Record<AdminCategory, typeof LayoutDashboard> = {
  overview: LayoutDashboard,
  doors: DoorClosed,
  activity: History,
}

export function AdminPanel({ visible, openCount }: { visible: boolean; openCount: number }) {
  const { t } = useTranslation()
  const [category, setCategory] = useState<AdminCategory>(() => {
    const view = new URLSearchParams(window.location.search).get('view')
    return import.meta.env.DEV && (view === 'doors' || view === 'activity') ? view : 'overview'
  })
  const [collapsed, setCollapsed] = useState(false)
  const [modal, setModal] = useState<ModalState>(() =>
    import.meta.env.DEV && new URLSearchParams(window.location.search).has('modal') ? { mode: 'create' } : null,
  )
  const [confirm, setConfirm] = useState<ConfirmState>(null)

  const {
    doors,
    activity,
    jobs,
    framework,
    storage,
    settings,
    loading,
    refresh,
    createDoor,
    updateDoor,
    deleteDoor,
    setDoorState,
    resetStates,
    teleportToDoor,
    highlightDoor,
  } = useAdminData()

  useEffect(() => {
    if (visible && openCount > 0) void refresh()
  }, [openCount, refresh, visible])

  const warningsCount = activity.filter((entry) => entry.severity === 'warning').length
  const HeaderIcon = HEADER_ICONS[category]

  const toggleState = (door: DoorItem) => void setDoorState(door.id, !door.locked)

  const handleConfirm = async () => {
    if (!confirm) return
    if (confirm.kind === 'delete') await deleteDoor(confirm.door.id)
    else await resetStates()
    setConfirm(null)
  }

  return (
    <div className="flex h-full w-full overflow-hidden bg-zinc-950 font-sans text-zinc-100 antialiased selection:bg-zinc-700">
      <AdminSidebar
        activeCategory={category}
        onSelectCategory={setCategory}
        doorsCount={doors.length}
        warningsCount={warningsCount}
        framework={framework}
        storage={storage}
        collapsed={collapsed}
        onToggleCollapse={() => setCollapsed((prev) => !prev)}
      />

      <div className="flex flex-1 flex-col overflow-hidden">
        <header className="flex h-16 shrink-0 items-center justify-between border-b border-zinc-800/80 bg-zinc-950/60 px-6 backdrop-blur-md">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-900 text-zinc-300">
              <HeaderIcon className="h-4 w-4" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-zinc-100">{t(`admin_header_${category}`)}</h2>
              <p className="text-[11px] text-zinc-400">{t(`admin_header_${category}_sub`)}</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Button onClick={() => void refresh()} disabled={loading} icon={<RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />}>
              <span className="hidden sm:inline">{t('btn_refresh')}</span>
            </Button>
            {category !== 'doors' && (
              <Button variant="primary" icon={<Plus className="h-3.5 w-3.5" />} onClick={() => setModal({ mode: 'create' })}>
                <span className="hidden sm:inline">{t('doors_create')}</span>
              </Button>
            )}
          </div>
        </header>

        <main className="flex-1 overflow-auto p-6">
          <AnimatePresence mode="wait">
            <motion.div
              key={category}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.2 }}
            >
              {category === 'overview' && (
                <OverviewView
                  doors={doors}
                  activity={activity}
                  onSelectCategory={setCategory}
                  onCreate={() => setModal({ mode: 'create' })}
                  onResetStates={() => setConfirm({ kind: 'reset' })}
                  onToggleState={toggleState}
                />
              )}

              {category === 'doors' && (
                <DoorsView
                  doors={doors}
                  jobs={jobs}
                  onCreate={() => setModal({ mode: 'create' })}
                  onEdit={(door) => setModal({ mode: 'edit', door })}
                  onDelete={(door) => setConfirm({ kind: 'delete', door })}
                  onToggleState={toggleState}
                  onTeleport={teleportToDoor}
                  onHighlight={highlightDoor}
                />
              )}

              {category === 'activity' && <ActivityView activity={activity} />}
            </motion.div>
          </AnimatePresence>
        </main>
      </div>

      <AnimatePresence>
        {modal && (
          <DoorModal
            key={modal.mode === 'edit' ? modal.door.id : 'create'}
            door={modal.mode === 'edit' ? modal.door : null}
            jobs={jobs}
            settings={settings}
            onClose={() => setModal(null)}
            onSubmit={(payload) => (modal.mode === 'edit' ? updateDoor(modal.door.id, payload) : createDoor(payload))}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirm && (
          <ConfirmModal
            title={confirm.kind === 'delete' ? t('confirm_delete_title') : t('confirm_reset_title')}
            description={confirm.kind === 'delete' ? t('confirm_delete_desc', { door: confirm.door.label }) : t('confirm_reset_desc')}
            confirmLabel={confirm.kind === 'delete' ? t('btn_delete') : t('btn_reset')}
            onConfirm={() => void handleConfirm()}
            onCancel={() => setConfirm(null)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
