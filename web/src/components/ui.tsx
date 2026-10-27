import { useState } from 'react'
import type { ButtonHTMLAttributes, InputHTMLAttributes, KeyboardEvent, ReactNode } from 'react'
import { X } from 'lucide-react'

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger'

const BUTTON_VARIANTS: Record<ButtonVariant, string> = {
  primary: 'border-zinc-700 bg-zinc-100 text-zinc-900 hover:bg-white',
  secondary: 'border-zinc-800 bg-zinc-900/80 text-zinc-300 hover:border-zinc-700 hover:bg-zinc-800 hover:text-white',
  ghost: 'border-transparent bg-transparent text-zinc-400 hover:bg-zinc-800/60 hover:text-zinc-200',
  danger: 'border-rose-500/30 bg-rose-500/10 text-rose-400 hover:bg-rose-500/20',
}

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  icon?: ReactNode
}

export function Button({ variant = 'secondary', icon, children, className = '', type = 'button', ...props }: ButtonProps) {
  return (
    <button
      type={type}
      className={`inline-flex items-center justify-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-semibold transition disabled:cursor-not-allowed disabled:opacity-50 ${BUTTON_VARIANTS[variant]} ${className}`}
      {...props}
    >
      {icon}
      {children}
    </button>
  )
}

export function IconButton({ className = '', ...props }: ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      type="button"
      className={`flex h-7 w-7 items-center justify-center rounded-md text-zinc-400 transition hover:bg-zinc-800/80 hover:text-zinc-100 disabled:opacity-40 ${className}`}
      {...props}
    />
  )
}

type BadgeTone = 'neutral' | 'success' | 'danger' | 'warning' | 'info' | 'violet'

const BADGE_TONES: Record<BadgeTone, string> = {
  neutral: 'border-zinc-700 bg-zinc-800/80 text-zinc-300',
  success: 'border-emerald-500/20 bg-emerald-500/10 text-emerald-400',
  danger: 'border-rose-500/20 bg-rose-500/10 text-rose-400',
  warning: 'border-amber-500/20 bg-amber-500/10 text-amber-400',
  info: 'border-sky-500/20 bg-sky-500/10 text-sky-400',
  violet: 'border-violet-500/20 bg-violet-500/10 text-violet-400',
}

export function Badge({ tone = 'neutral', icon, children, title }: { tone?: BadgeTone; icon?: ReactNode; children: ReactNode; title?: string }) {
  return (
    <span title={title} className={`inline-flex items-center gap-1 rounded-md border px-1.5 py-0.5 text-[10px] font-semibold ${BADGE_TONES[tone]}`}>
      {icon}
      {children}
    </span>
  )
}

export function Toggle({ checked, onChange, disabled }: { checked: boolean; onChange: (value: boolean) => void; disabled?: boolean }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`relative h-5 w-9 shrink-0 rounded-full border transition disabled:opacity-50 ${checked ? 'border-emerald-500/40 bg-emerald-500/30' : 'border-zinc-700 bg-zinc-800'}`}
    >
      <span className={`absolute top-0.5 h-3.5 w-3.5 rounded-full transition-all ${checked ? 'left-[18px] bg-emerald-400' : 'left-0.5 bg-zinc-400'}`} />
    </button>
  )
}

export function Field({ label, hint, children, className = '' }: { label: string; hint?: string; children: ReactNode; className?: string }) {
  return (
    <div className={`space-y-1.5 ${className}`}>
      <label className="block text-xs font-semibold text-zinc-300">{label}</label>
      {children}
      {hint && <p className="text-[11px] text-zinc-500">{hint}</p>}
    </div>
  )
}

export const inputClass =
  'w-full rounded-lg border border-zinc-800 bg-zinc-900 px-3 py-2 text-xs text-zinc-100 placeholder-zinc-500 transition focus:border-zinc-600 focus:outline-none'

export function TextInput({ className = '', ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return <input className={`${inputClass} ${className}`} {...props} />
}

export function OptionRow({ icon, title, description, checked, onChange }: { icon: ReactNode; title: string; description: string; checked: boolean; onChange: (value: boolean) => void }) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-lg border border-zinc-800 bg-zinc-900/50 px-3 py-2.5">
      <div className="flex items-center gap-2.5">
        <span className="text-zinc-400">{icon}</span>
        <div>
          <p className="text-xs font-semibold text-zinc-200">{title}</p>
          <p className="text-[11px] text-zinc-500">{description}</p>
        </div>
      </div>
      <Toggle checked={checked} onChange={onChange} />
    </div>
  )
}

export function TagInput({ values, onChange, placeholder }: { values: string[]; onChange: (values: string[]) => void; placeholder?: string }) {
  const [draft, setDraft] = useState('')

  const commit = () => {
    const value = draft.trim().replace(/,$/, '')
    if (value && !values.includes(value)) onChange([...values, value])
    setDraft('')
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault()
      commit()
    } else if (e.key === 'Backspace' && draft === '' && values.length > 0) {
      onChange(values.slice(0, -1))
    }
  }

  return (
    <div className="flex min-h-[38px] flex-wrap items-center gap-1.5 rounded-lg border border-zinc-800 bg-zinc-900 px-2 py-1.5 focus-within:border-zinc-600">
      {values.map((value) => (
        <span key={value} className="inline-flex items-center gap-1 rounded-md border border-zinc-700 bg-zinc-800 px-1.5 py-0.5 font-mono text-[11px] text-zinc-200">
          {value}
          <button type="button" onClick={() => onChange(values.filter((v) => v !== value))} className="text-zinc-500 hover:text-zinc-200">
            <X className="h-3 w-3" />
          </button>
        </span>
      ))}
      <input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={handleKeyDown}
        onBlur={commit}
        placeholder={values.length === 0 ? placeholder : undefined}
        className="min-w-[120px] flex-1 bg-transparent px-1 text-xs text-zinc-100 placeholder-zinc-500 focus:outline-none"
      />
    </div>
  )
}

export function EmptyState({ icon, title, description, action }: { icon: ReactNode; title: string; description: string; action?: ReactNode }) {
  return (
    <div className="flex h-64 flex-col items-center justify-center rounded-xl border border-dashed border-zinc-800 bg-zinc-900/10 p-6 text-center">
      <div className="mb-2 text-zinc-600">{icon}</div>
      <p className="text-sm font-medium text-zinc-400">{title}</p>
      <p className="mt-1 max-w-xs text-xs text-zinc-500">{description}</p>
      {action && <div className="mt-4">{action}</div>}
    </div>
  )
}
