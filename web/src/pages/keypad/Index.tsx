import { useCallback, useEffect, useState } from 'react'
import { motion } from 'motion/react'
import { Delete, KeyRound, Lock, LockOpen, X } from 'lucide-react'
import { useTranslation } from '../../hooks/useTranslation'
import type { KeypadData, PinResult } from '../../types/doors'
import { fetchNui } from '../../utils/fetchNui'
import { isEnvBrowser } from '../../utils/nui'

const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'clear', '0', 'back']

export function KeypadPanel({ data }: { data: KeypadData }) {
  const { t } = useTranslation()
  const [pin, setPin] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [shake, setShake] = useState(0)
  const [pending, setPending] = useState(false)
  const [success, setSuccess] = useState(false)

  const press = useCallback((key: string) => {
    if (pending || success) return
    setError(null)
    if (key === 'clear') setPin('')
    else if (key === 'back') setPin((prev) => prev.slice(0, -1))
    else setPin((prev) => (prev.length < data.maxLength ? prev + key : prev))
  }, [data.maxLength, pending, success])

  const submit = useCallback(async () => {
    if (pending || success || pin.length < data.minLength) return
    setPending(true)

    let result: PinResult
    try {
      result = isEnvBrowser()
        ? { ok: pin === '4512', reason: 'pin_wrong', attemptsLeft: 3 }
        : await fetchNui<PinResult>('submitPin', { pin })
    } catch (err) {
      result = { ok: false, reason: err instanceof Error ? err.message : 'timeout' }
    }

    setPending(false)
    if (result.ok) {
      setSuccess(true)
      return
    }

    setPin('')
    setShake((count) => count + 1)
    setError(
      result.reason === 'pin_wrong' && result.attemptsLeft !== undefined
        ? t('keypad_wrong', { n: result.attemptsLeft })
        : t(`reason_${result.reason ?? 'denied'}`),
    )
  }, [data.minLength, pending, pin, success, t])

  useEffect(() => {
    const listener = (event: KeyboardEvent) => {
      if (/^[0-9]$/.test(event.key)) press(event.key)
      else if (event.key === 'Backspace') press('back')
      else if (event.key === 'Delete') press('clear')
      else if (event.key === 'Enter') void submit()
    }
    window.addEventListener('keydown', listener)
    return () => window.removeEventListener('keydown', listener)
  }, [press, submit])

  const StateIcon = success ? LockOpen : Lock

  return (
    <div className="w-[300px] p-5 text-zinc-100 select-none">
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className={`flex h-10 w-10 items-center justify-center rounded-xl border ${success ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400' : 'border-zinc-800 bg-zinc-900 text-zinc-300'}`}>
            <StateIcon className="h-5 w-5" />
          </div>
          <div className="min-w-0">
            <p className="text-[10px] font-semibold uppercase tracking-widest text-zinc-500">{t('keypad_title')}</p>
            <p className="truncate text-sm font-bold text-zinc-100">{data.label}</p>
          </div>
        </div>
        <button type="button" onClick={() => void fetchNui('close')} className="rounded-md p-1 text-zinc-500 transition hover:bg-zinc-800 hover:text-zinc-200">
          <X className="h-4 w-4" />
        </button>
      </div>

      <motion.div
        key={shake}
        animate={shake > 0 ? { x: [0, -8, 8, -6, 6, -3, 0] } : undefined}
        transition={{ duration: 0.35 }}
        className={`mt-5 flex h-14 items-center justify-center gap-2.5 rounded-xl border bg-zinc-900/80 ${error ? 'border-rose-500/40' : success ? 'border-emerald-500/40' : 'border-zinc-800'}`}
      >
        {pin.length === 0 && !success ? (
          <span className="flex items-center gap-1.5 text-xs text-zinc-500">
            <KeyRound className="h-3.5 w-3.5" />
            {t('keypad_enter_code')}
          </span>
        ) : (
          Array.from({ length: Math.max(pin.length, data.minLength) }).map((_, index) => (
            <span
              key={index}
              className={`h-3 w-3 rounded-full transition ${success ? 'bg-emerald-400' : index < pin.length ? 'bg-zinc-100' : 'bg-zinc-700'}`}
            />
          ))
        )}
      </motion.div>

      <p className={`mt-2 h-4 text-center text-[11px] ${error ? 'text-rose-400' : 'text-emerald-400'}`}>
        {error ?? (success ? t('keypad_success') : '')}
      </p>

      <div className="mt-3 grid grid-cols-3 gap-2">
        {KEYS.map((key) => (
          <button
            key={key}
            type="button"
            onClick={() => press(key)}
            disabled={pending || success}
            className="flex h-12 items-center justify-center rounded-xl border border-zinc-800 bg-zinc-900/70 text-lg font-semibold text-zinc-200 transition hover:border-zinc-700 hover:bg-zinc-800 active:scale-95 disabled:opacity-40"
          >
            {key === 'back' ? <Delete className="h-5 w-5" /> : key === 'clear' ? <span className="text-xs font-bold text-zinc-400">C</span> : key}
          </button>
        ))}
      </div>

      <button
        type="button"
        onClick={() => void submit()}
        disabled={pending || success || pin.length < data.minLength}
        className="mt-3 w-full rounded-xl border border-zinc-700 bg-zinc-100 py-2.5 text-sm font-bold text-zinc-900 transition hover:bg-white disabled:opacity-40"
      >
        {pending ? t('keypad_checking') : data.locked ? t('keypad_unlock') : t('keypad_lock')}
      </button>
    </div>
  )
}
