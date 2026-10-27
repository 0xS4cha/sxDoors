import { motion } from 'motion/react'
import type { ReactNode } from 'react'
import { useEscapeKey } from '../hooks/useEscapeKey'
import { fetchNui } from '../utils/fetchNui'

interface NuiWrapperProps {
  visible: boolean
  compact?: boolean
  children: ReactNode
}

export function NuiWrapper({ visible, compact = false, children }: NuiWrapperProps) {
  const handleClose = () => {
    void fetchNui('close')
  }

  useEscapeKey(handleClose, visible)

  return (
    <motion.div
      className={`fixed inset-0 flex items-center justify-center p-6 ${compact ? 'bg-black/30' : 'bg-black/60'} ${visible ? '' : 'pointer-events-none'}`}
      initial={false}
      animate={{ opacity: visible ? 1 : 0 }}
      transition={{ duration: 0.2 }}
    >
      <motion.div
        className={
          compact
            ? 'overflow-hidden rounded-2xl border border-white/10 bg-zinc-950/95 shadow-2xl backdrop-blur-md'
            : 'flex h-[min(90vh,760px)] w-[min(94vw,1180px)] flex-col overflow-hidden rounded-2xl border border-white/10 bg-zinc-950/95 shadow-2xl backdrop-blur-md'
        }
        initial={false}
        animate={visible ? { opacity: 1, y: 0, scale: 1 } : { opacity: 0, y: 16, scale: 0.98 }}
        transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
      >
        {children}
      </motion.div>
    </motion.div>
  )
}
