import { useCallback, useEffect, useState } from 'react'
import { NuiWrapper } from './components/NuiWrapper'
import { useNuiEvent } from './hooks/useNuiEvent'
import { useTranslation } from './hooks/useTranslation'
import { AdminPanel } from './pages/admin/Index'
import { KeypadPanel } from './pages/keypad/Index'
import type { KeypadData } from './types/doors'
import type { PanelRoute, SetRouteData, SetVisibleData } from './types/nui'
import { debugData } from './utils/debugData'
import { fetchNui } from './utils/fetchNui'
import { isEnvBrowser } from './utils/nui'

const MOCK_KEYPAD: KeypadData = { doorId: 'DOOR-D4E5F6', label: 'LSPD - Armory', locked: true, minLength: 4, maxLength: 8 }

function getInitialRoute(): PanelRoute {
  if (isEnvBrowser() && new URLSearchParams(window.location.search).get('route') === 'keypad') {
    return 'keypad'
  }
  return 'admin'
}

export default function App() {
  const [visible, setVisible] = useState(isEnvBrowser())
  const [route, setRoute] = useState<PanelRoute>(getInitialRoute)
  const [keypad, setKeypad] = useState<KeypadData | null>(isEnvBrowser() ? MOCK_KEYPAD : null)
  const [openCount, setOpenCount] = useState(0)

  useTranslation()

  const handleSetVisible = useCallback(({ visible: nextVisible }: SetVisibleData) => {
    setVisible(nextVisible)
  }, [])

  useNuiEvent<SetVisibleData>('setVisible', handleSetVisible)

  useNuiEvent<SetRouteData<KeypadData>>('setRoute', ({ route: nextRoute, data }) => {
    setRoute(nextRoute)
    if (nextRoute === 'keypad' && data) setKeypad(data)
    setOpenCount((count) => count + 1)
  })

  useEffect(() => {
    void fetchNui('nuiReady', { ok: true })

    if (import.meta.env.DEV && isEnvBrowser()) {
      const locale = new URLSearchParams(window.location.search).get('lang') ?? 'en'
      void import('virtual:dev-translations').then(({ default: languages }) => {
        debugData([{ action: 'setTranslations', data: { locale, translations: { ...languages.en, ...languages[locale] } } }])
      })
    }
  }, [])

  return (
    <NuiWrapper visible={visible} compact={route === 'keypad'}>
      {route === 'admin' && <AdminPanel visible={visible} openCount={openCount} />}
      {route === 'keypad' && keypad && <KeypadPanel key={`${keypad.doorId}-${openCount}`} data={keypad} />}
    </NuiWrapper>
  )
}
