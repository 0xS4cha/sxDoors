import { useMemo, useState } from 'react'
import { motion } from 'motion/react'
import {
  Briefcase,
  Crosshair,
  EyeOff,
  KeyRound,
  LocateFixed,
  Lock,
  MousePointerClick,
  Plus,
  Settings2,
  ShieldCheck,
  Skull,
  Trash2,
  Wrench,
  X,
} from 'lucide-react'
import { Button, Field, IconButton, OptionRow, TagInput, TextInput, inputClass } from '../../../components/ui'
import { useNuiEvent } from '../../../hooks/useNuiEvent'
import { useTranslation } from '../../../hooks/useTranslation'
import type { ActionResult, AdminSettings, DoorEntity, DoorItem, DoorPayload, DoorType, IllegalGroup, JobItem, PickerResult, Vec3 } from '../../../types/doors'
import { fetchNui } from '../../../utils/fetchNui'
import { formatCoords } from '../../../utils/format'
import { isEnvBrowser } from '../../../utils/nui'
import { DOOR_TYPES, getDoorTypeMeta } from './doorMeta'

type Tab = 'general' | 'entities' | 'access'

interface JobRule {
  name: string
  grade: number
}

interface GroupRule {
  id: string
  grade: number
}

interface DoorModalProps {
  door: DoorItem | null
  jobs: JobItem[]
  illegalGroups: IllegalGroup[]
  settings: AdminSettings
  onClose: () => void
  onSubmit: (payload: DoorPayload) => Promise<ActionResult>
}

const round = (value: number) => Math.round(value * 100) / 100

function centerOf(entities: DoorEntity[]): Vec3 | null {
  if (entities.length === 0) return null
  const sum = entities.reduce((acc, e) => ({ x: acc.x + e.coords.x, y: acc.y + e.coords.y, z: acc.z + e.coords.z }), { x: 0, y: 0, z: 0 })
  return { x: round(sum.x / entities.length), y: round(sum.y / entities.length), z: round(sum.z / entities.length) }
}

export function DoorModal({ door, jobs, illegalGroups, settings, onClose, onSubmit }: DoorModalProps) {
  const { t } = useTranslation()
  const [tab, setTab] = useState<Tab>('general')
  const [label, setLabel] = useState(door?.label ?? '')
  const [type, setType] = useState<DoorType>(door?.type ?? 'single')
  const [entities, setEntities] = useState<DoorEntity[]>(door?.entities ?? [])
  const [customCoords, setCustomCoords] = useState<Vec3 | null>(() => {
    if (!door) return null
    const center = centerOf(door.entities)
    const same = center && Math.abs(center.x - door.coords.x) < 0.05 && Math.abs(center.y - door.coords.y) < 0.05 && Math.abs(center.z - door.coords.z) < 0.05
    return same ? null : door.coords
  })
  const [distance, setDistance] = useState(door?.distance ?? settings.defaultDistance)
  const [defaultLocked, setDefaultLocked] = useState(door?.defaultLocked ?? true)
  const [autoLock, setAutoLock] = useState(door?.autoLock ?? 0)
  const [lockpick, setLockpick] = useState(door?.lockpick ?? false)
  const [hidePrompt, setHidePrompt] = useState(door?.hidePrompt ?? false)
  const [pin, setPin] = useState(door?.pin ?? '')
  const [jobRules, setJobRules] = useState<JobRule[]>(
    Object.entries(door?.access.jobs ?? {}).map(([name, grade]) => ({ name, grade })),
  )
  const [groupRules, setGroupRules] = useState<GroupRule[]>(
    Object.entries(door?.access.groups ?? {}).map(([id, grade]) => ({ id, grade })),
  )
  const [items, setItems] = useState<string[]>(door?.access.items ?? [])
  const [aces, setAces] = useState<string[]>(door?.access.aces ?? [])
  const [identifiers, setIdentifiers] = useState<string[]>(door?.access.identifiers ?? [])
  const [picking, setPicking] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const maxEntities = getDoorTypeMeta(type).maxEntities
  const interactionPoint = customCoords ?? centerOf(entities)
  const hasEsxJobs = jobs.length > 0

  useNuiEvent<PickerResult>('pickerResult', (result) => {
    setPicking(false)
    if (!result || result.cancelled || !result.entities || result.entities.length === 0) return

    const picked = result.entities.map((entity) => ({
      model: entity.model,
      coords: { x: round(entity.coords.x), y: round(entity.coords.y), z: round(entity.coords.z) },
      heading: round(entity.heading),
    }))
    setEntities(picked)
    if (picked.length >= 2 && type === 'single') setType('double')
    if (picked.length === 1 && type === 'double') setType('single')
    setError(null)
  })

  const startPicker = async () => {
    if (isEnvBrowser()) {
      setEntities([{ model: 'v_ilev_ph_door01', coords: { x: 434.74, y: -983.21, z: 30.84 }, heading: 270 }])
      return
    }
    setPicking(true)
    await fetchNui('startPicker', { max: maxEntities })
  }

  const takeMyPosition = async () => {
    const coords = isEnvBrowser() ? { x: 435.1, y: -982.4, z: 30.7 } : await fetchNui<Vec3>('getCurrentCoords')
    if (coords) setCustomCoords({ x: round(coords.x), y: round(coords.y), z: round(coords.z) })
  }

  const updateEntity = (index: number, patch: Partial<DoorEntity>) => {
    setEntities((prev) => prev.map((entity, i) => (i === index ? { ...entity, ...patch } : entity)))
  }

  const updateEntityCoord = (index: number, axis: keyof Vec3, value: number) => {
    setEntities((prev) => prev.map((entity, i) => (i === index ? { ...entity, coords: { ...entity.coords, [axis]: value } } : entity)))
  }

  const addEmptyEntity = () => {
    const base = interactionPoint ?? { x: 0, y: 0, z: 0 }
    setEntities((prev) => [...prev, { model: '', coords: { ...base }, heading: 0 }])
  }

  const validation = useMemo(() => {
    if (!label.trim()) return { tab: 'general' as Tab, key: 'error_missing_label' }
    if (entities.length === 0 || entities.some((e) => String(e.model).trim() === '')) return { tab: 'entities' as Tab, key: 'error_missing_entities' }
    if (pin !== '' && (!/^\d+$/.test(pin) || pin.length < settings.pinMinLength || pin.length > settings.pinMaxLength)) {
      return { tab: 'access' as Tab, key: 'error_invalid_pin' }
    }
    if (jobRules.some((rule) => rule.name.trim() === '')) return { tab: 'access' as Tab, key: 'error_invalid_job' }
    if (groupRules.some((rule) => rule.id === '')) return { tab: 'access' as Tab, key: 'error_invalid_group' }
    return null
  }, [entities, groupRules, jobRules, label, pin, settings.pinMaxLength, settings.pinMinLength])

  const handleSubmit = async () => {
    if (validation) {
      setTab(validation.tab)
      setError(t(validation.key, { min: settings.pinMinLength, max: settings.pinMaxLength }))
      return
    }

    const jobsRecord: Record<string, number> = {}
    jobRules.forEach((rule) => { jobsRecord[rule.name.trim()] = Math.max(0, Math.floor(rule.grade)) })

    const groupsRecord: Record<string, number> = {}
    groupRules.forEach((rule) => { groupsRecord[rule.id] = Math.max(0, Math.floor(rule.grade)) })

    setSubmitting(true)
    const result = await onSubmit({
      label: label.trim(),
      type,
      entities: entities.map((entity) => ({
        ...entity,
        model: typeof entity.model === 'string' && /^-?\d+$/.test(entity.model.trim()) ? Number(entity.model) : entity.model,
      })),
      coords: interactionPoint ?? { x: 0, y: 0, z: 0 },
      distance,
      defaultLocked,
      autoLock,
      lockpick,
      hidePrompt,
      pin,
      access: { jobs: jobsRecord, groups: groupsRecord, items, aces, identifiers },
    })
    setSubmitting(false)

    if (result.ok) onClose()
    else setError(t(`error_${result.error ?? 'unknown'}`, { min: settings.pinMinLength, max: settings.pinMaxLength }))
  }

  const tabs: { id: Tab; label: string; icon: typeof Settings2; count?: number }[] = [
    { id: 'general', label: t('modal_tab_general'), icon: Settings2 },
    { id: 'entities', label: t('modal_tab_entities'), icon: Crosshair, count: entities.length },
    { id: 'access', label: t('modal_tab_access'), icon: ShieldCheck, count: jobRules.length + groupRules.length + items.length + aces.length + identifiers.length + (pin ? 1 : 0) },
  ]

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-40 flex items-center justify-center bg-black/70 p-4 backdrop-blur-xs"
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 12 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 12 }}
        transition={{ duration: 0.2 }}
        className="flex max-h-[min(86vh,700px)] w-full max-w-2xl flex-col rounded-2xl border border-zinc-800 bg-zinc-950 shadow-2xl"
      >
        <div className="flex items-center justify-between border-b border-zinc-800 px-6 py-4">
          <div className="flex items-center gap-2">
            {door ? <Settings2 className="h-5 w-5 text-zinc-200" /> : <Plus className="h-5 w-5 text-zinc-200" />}
            <div>
              <h3 className="text-base font-bold text-zinc-100">{door ? t('modal_edit_title') : t('modal_create_title')}</h3>
              {door && <p className="font-mono text-[11px] text-zinc-500">{door.id}</p>}
            </div>
          </div>
          <button type="button" onClick={onClose} className="rounded-lg p-1 text-zinc-400 hover:bg-zinc-800 hover:text-zinc-200">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex gap-1 border-b border-zinc-800 px-6 pt-3">
          {tabs.map((item) => {
            const Icon = item.icon
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setTab(item.id)}
                className={`flex items-center gap-1.5 border-b-2 px-3 pb-2.5 text-xs font-semibold transition ${tab === item.id ? 'border-zinc-100 text-zinc-100' : 'border-transparent text-zinc-500 hover:text-zinc-300'}`}
              >
                <Icon className="h-3.5 w-3.5" />
                {item.label}
                {item.count !== undefined && item.count > 0 && (
                  <span className="rounded-full bg-zinc-800 px-1.5 text-[10px] text-zinc-300">{item.count}</span>
                )}
              </button>
            )
          })}
        </div>

        <div className="flex-1 space-y-5 overflow-auto px-6 py-5">
          {tab === 'general' && (
            <>
              <Field label={t('modal_label')}>
                <TextInput autoFocus value={label} maxLength={100} placeholder={t('modal_label_placeholder')} onChange={(e) => setLabel(e.target.value)} />
              </Field>

              <Field label={t('modal_type')}>
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                  {DOOR_TYPES.map((item) => {
                    const Icon = item.icon
                    const active = type === item.id
                    return (
                      <button
                        key={item.id}
                        type="button"
                        onClick={() => setType(item.id)}
                        className={`flex flex-col items-center gap-1.5 rounded-lg border px-2 py-3 text-xs font-semibold transition ${active ? 'border-zinc-500 bg-zinc-800 text-zinc-100' : 'border-zinc-800 bg-zinc-900/60 text-zinc-400 hover:border-zinc-700'}`}
                      >
                        <Icon className="h-5 w-5" />
                        {t(`door_type_${item.id}`)}
                      </button>
                    )
                  })}
                </div>
                <p className="text-[11px] text-zinc-500">{t(`door_type_${type}_desc`)}</p>
              </Field>

              <div className="grid grid-cols-2 gap-4">
                <Field label={t('modal_distance')} hint={t('modal_distance_hint')}>
                  <TextInput type="number" min={0.5} max={30} step={0.5} value={distance} onChange={(e) => setDistance(Number(e.target.value))} />
                </Field>
                <Field label={t('modal_autolock')} hint={t('modal_autolock_hint')}>
                  <TextInput type="number" min={0} max={3600} value={autoLock} onChange={(e) => setAutoLock(Math.max(0, Number(e.target.value)))} />
                </Field>
              </div>

              <div className="space-y-2">
                <OptionRow
                  icon={<Lock className="h-4 w-4" />}
                  title={t('modal_default_locked')}
                  description={settings.persistState ? t('modal_default_locked_desc_persist') : t('modal_default_locked_desc')}
                  checked={defaultLocked}
                  onChange={setDefaultLocked}
                />
                <OptionRow
                  icon={<Wrench className="h-4 w-4" />}
                  title={t('modal_lockpick')}
                  description={settings.lockpick ? t('modal_lockpick_desc') : t('modal_lockpick_disabled')}
                  checked={lockpick}
                  onChange={setLockpick}
                />
                <OptionRow
                  icon={<EyeOff className="h-4 w-4" />}
                  title={t('modal_hide_prompt')}
                  description={t('modal_hide_prompt_desc')}
                  checked={hidePrompt}
                  onChange={setHidePrompt}
                />
              </div>
            </>
          )}

          {tab === 'entities' && (
            <>
              <div className="flex flex-col gap-3 rounded-xl border border-zinc-800 bg-zinc-900/40 p-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p className="text-xs font-semibold text-zinc-200">{t('modal_picker_title')}</p>
                  <p className="mt-0.5 text-[11px] text-zinc-500">{t('modal_picker_desc', { n: maxEntities })}</p>
                </div>
                <Button variant="primary" disabled={picking} icon={<MousePointerClick className="h-3.5 w-3.5" />} onClick={() => void startPicker()}>
                  {picking ? t('modal_picker_running') : t('modal_picker_start')}
                </Button>
              </div>

              <div className="space-y-2">
                {entities.length === 0 && <p className="py-4 text-center text-xs text-zinc-500">{t('modal_no_entities')}</p>}
                {entities.map((entity, index) => (
                  <div key={index} className="space-y-2 rounded-lg border border-zinc-800 bg-zinc-900/40 p-3">
                    <div className="flex items-center gap-2">
                      <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-zinc-800 text-[11px] font-bold text-zinc-300">{index + 1}</span>
                      <input
                        value={String(entity.model)}
                        placeholder={t('modal_model_placeholder')}
                        onChange={(e) => updateEntity(index, { model: e.target.value })}
                        className={`${inputClass} font-mono`}
                      />
                      <IconButton onClick={() => setEntities((prev) => prev.filter((_, i) => i !== index))} className="hover:bg-rose-500/10 hover:text-rose-400">
                        <Trash2 className="h-3.5 w-3.5" />
                      </IconButton>
                    </div>
                    <div className="grid grid-cols-4 gap-2 pl-8">
                      {(['x', 'y', 'z'] as const).map((axis) => (
                        <input
                          key={axis}
                          type="number"
                          step={0.01}
                          value={entity.coords[axis]}
                          onChange={(e) => updateEntityCoord(index, axis, Number(e.target.value))}
                          className={`${inputClass} font-mono`}
                          title={axis.toUpperCase()}
                        />
                      ))}
                      <input
                        type="number"
                        step={0.1}
                        value={entity.heading}
                        onChange={(e) => updateEntity(index, { heading: Number(e.target.value) })}
                        className={`${inputClass} font-mono`}
                        title={t('modal_heading')}
                      />
                    </div>
                  </div>
                ))}
                {entities.length < 4 && (
                  <button type="button" onClick={addEmptyEntity} className="w-full rounded-lg border border-dashed border-zinc-800 py-2 text-xs text-zinc-500 transition hover:border-zinc-700 hover:text-zinc-300">
                    + {t('modal_add_manual')}
                  </button>
                )}
              </div>

              <Field label={t('modal_interaction_point')} hint={customCoords ? t('modal_interaction_custom') : t('modal_interaction_auto')}>
                <div className="flex items-center gap-2">
                  <div className={`${inputClass} font-mono text-zinc-300`}>{interactionPoint ? formatCoords(interactionPoint) : '—'}</div>
                  <Button icon={<LocateFixed className="h-3.5 w-3.5" />} onClick={() => void takeMyPosition()} className="shrink-0 py-2">
                    {t('modal_use_my_position')}
                  </Button>
                  {customCoords && (
                    <Button variant="ghost" onClick={() => setCustomCoords(null)} className="shrink-0 py-2">{t('modal_reset_center')}</Button>
                  )}
                </div>
              </Field>
            </>
          )}

          {tab === 'access' && (
            <>
              <p className="rounded-lg border border-zinc-800 bg-zinc-900/40 px-3 py-2.5 text-[11px] leading-relaxed text-zinc-400">{t('modal_access_help')}</p>

              <Field label={t('modal_jobs')} hint={hasEsxJobs ? t('modal_jobs_hint') : t('modal_jobs_hint_standalone')}>
                <div className="space-y-2">
                  {jobRules.map((rule, index) => {
                    const job = jobs.find((j) => j.name === rule.name)
                    return (
                      <div key={index} className="flex items-center gap-2">
                        <Briefcase className="h-4 w-4 shrink-0 text-zinc-500" />
                        {hasEsxJobs ? (
                          <select
                            value={rule.name}
                            onChange={(e) => setJobRules((prev) => prev.map((r, i) => (i === index ? { name: e.target.value, grade: 0 } : r)))}
                            className={inputClass}
                          >
                            <option value="">{t('modal_select_job')}</option>
                            {jobs.map((j) => (
                              <option key={j.name} value={j.name}>{j.label} ({j.name})</option>
                            ))}
                          </select>
                        ) : (
                          <TextInput
                            value={rule.name}
                            placeholder="police"
                            onChange={(e) => setJobRules((prev) => prev.map((r, i) => (i === index ? { ...r, name: e.target.value } : r)))}
                          />
                        )}
                        {job && job.grades.length > 0 ? (
                          <select
                            value={rule.grade}
                            onChange={(e) => setJobRules((prev) => prev.map((r, i) => (i === index ? { ...r, grade: Number(e.target.value) } : r)))}
                            className={`${inputClass} max-w-[180px]`}
                          >
                            {job.grades.map((g) => (
                              <option key={g.grade} value={g.grade}>≥ {g.label} ({g.grade})</option>
                            ))}
                          </select>
                        ) : (
                          <TextInput
                            type="number"
                            min={0}
                            value={rule.grade}
                            title={t('modal_min_grade')}
                            onChange={(e) => setJobRules((prev) => prev.map((r, i) => (i === index ? { ...r, grade: Number(e.target.value) } : r)))}
                            className="max-w-[90px]"
                          />
                        )}
                        <IconButton onClick={() => setJobRules((prev) => prev.filter((_, i) => i !== index))} className="hover:bg-rose-500/10 hover:text-rose-400">
                          <Trash2 className="h-3.5 w-3.5" />
                        </IconButton>
                      </div>
                    )
                  })}
                  <button
                    type="button"
                    onClick={() => setJobRules((prev) => [...prev, { name: '', grade: 0 }])}
                    className="w-full rounded-lg border border-dashed border-zinc-800 py-2 text-xs text-zinc-500 transition hover:border-zinc-700 hover:text-zinc-300"
                  >
                    + {t('modal_add_job')}
                  </button>
                </div>
              </Field>

              {(settings.sxIllegals || groupRules.length > 0) && (
                <Field label={t('modal_groups')} hint={settings.sxIllegals ? t('modal_groups_hint') : t('modal_groups_hint_offline')}>
                  <div className="space-y-2">
                    {groupRules.map((rule, index) => {
                      const group = illegalGroups.find((g) => g.id === rule.id)
                      return (
                        <div key={index} className="flex items-center gap-2">
                          <Skull className="h-4 w-4 shrink-0" style={{ color: group?.color ?? '#71717a' }} />
                          <select
                            value={rule.id}
                            onChange={(e) => setGroupRules((prev) => prev.map((r, i) => (i === index ? { id: e.target.value, grade: settings.anyGroupGrade } : r)))}
                            className={inputClass}
                          >
                            <option value="">{t('modal_select_group')}</option>
                            {!group && rule.id && <option value={rule.id}>{rule.id}</option>}
                            {illegalGroups.map((g) => (
                              <option key={g.id} value={g.id}>{g.name}</option>
                            ))}
                          </select>
                          <select
                            value={rule.grade}
                            onChange={(e) => setGroupRules((prev) => prev.map((r, i) => (i === index ? { ...r, grade: Number(e.target.value) } : r)))}
                            className={`${inputClass} max-w-[200px]`}
                          >
                            <option value={settings.anyGroupGrade}>{t('modal_group_any_rank')}</option>
                            {(group?.ranks ?? []).map((rank) => (
                              <option key={rank.grade} value={rank.grade}>≥ {rank.label}</option>
                            ))}
                            {!group && rule.grade < settings.anyGroupGrade && <option value={rule.grade}>≥ {rule.grade}</option>}
                          </select>
                          <IconButton onClick={() => setGroupRules((prev) => prev.filter((_, i) => i !== index))} className="hover:bg-rose-500/10 hover:text-rose-400">
                            <Trash2 className="h-3.5 w-3.5" />
                          </IconButton>
                        </div>
                      )
                    })}
                    {settings.sxIllegals && (
                      <button
                        type="button"
                        onClick={() => setGroupRules((prev) => [...prev, { id: '', grade: settings.anyGroupGrade }])}
                        className="w-full rounded-lg border border-dashed border-zinc-800 py-2 text-xs text-zinc-500 transition hover:border-zinc-700 hover:text-zinc-300"
                      >
                        + {t('modal_add_group')}
                      </button>
                    )}
                  </div>
                </Field>
              )}

              <Field label={t('modal_items')} hint={t('modal_items_hint')}>
                <TagInput values={items} onChange={setItems} placeholder="key_lspd" />
              </Field>

              <Field label={t('modal_aces')} hint={t('modal_aces_hint')}>
                <TagInput values={aces} onChange={setAces} placeholder="sxdoors.lspd" />
              </Field>

              <Field label={t('modal_identifiers')} hint={t('modal_identifiers_hint')}>
                <TagInput values={identifiers} onChange={setIdentifiers} placeholder="license:xxxxxxxx" />
              </Field>

              <Field label={t('modal_pin')} hint={t('modal_pin_hint', { min: settings.pinMinLength, max: settings.pinMaxLength })}>
                <div className="relative">
                  <KeyRound className="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-zinc-500" />
                  <TextInput
                    value={pin}
                    inputMode="numeric"
                    maxLength={settings.pinMaxLength}
                    placeholder={t('modal_pin_placeholder')}
                    onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
                    className="pl-9 font-mono tracking-[0.3em]"
                  />
                </div>
              </Field>
            </>
          )}
        </div>

        <div className="flex items-center justify-between gap-3 border-t border-zinc-800 px-6 py-4">
          <p className="min-h-4 text-[11px] text-rose-400">{error}</p>
          <div className="flex shrink-0 gap-2">
            <Button onClick={onClose}>{t('btn_cancel')}</Button>
            <Button variant="primary" disabled={submitting} onClick={() => void handleSubmit()}>
              {door ? t('modal_save') : t('modal_create')}
            </Button>
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
}
