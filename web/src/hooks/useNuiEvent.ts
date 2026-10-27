import { useEffect, useRef } from 'react'
import type { NuiMessage } from '../types/nui'

export function useNuiEvent<T = unknown>(
  action: string,
  handler: (data: T) => void,
): void {
  const savedHandler = useRef(handler)

  useEffect(() => {
    savedHandler.current = handler
  }, [handler])

  useEffect(() => {
    const listener = (event: MessageEvent<NuiMessage<T>>) => {
      const { action: eventAction, data } = event.data ?? {}

      if (eventAction === action) {
        savedHandler.current(data)
      }
    }

    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [action])
}
