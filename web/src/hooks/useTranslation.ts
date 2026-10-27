import { useState, useEffect, useCallback } from 'react'
import { useNuiEvent } from './useNuiEvent'
import type { PhraseDictionary, SetLocaleData, SetTranslationsData } from '../types/nui'

export type Locale = string

interface TranslationSnapshot {
  locale: Locale
  translations: PhraseDictionary
}

let currentLocale: Locale = 'en'
let currentTranslations: PhraseDictionary = {}
const listeners = new Set<(snapshot: TranslationSnapshot) => void>()

function normalizeLocale(locale: string): Locale {
  const normalized = (locale || '').toLowerCase().trim()
  if (normalized == '') {
    return 'en'
  }

  return normalized
}

function notifyListeners() {
  const snapshot: TranslationSnapshot = {
    locale: currentLocale,
    translations: currentTranslations,
  }
  listeners.forEach((listener) => listener(snapshot))
}

export function setGlobalLocale(locale: Locale) {
  currentLocale = normalizeLocale(locale)
  notifyListeners()
}

function setGlobalTranslations(locale: Locale, translations: PhraseDictionary) {
  currentLocale = normalizeLocale(locale)
  currentTranslations = translations || {}
  notifyListeners()
}

export function useTranslation() {
  const [locale, setLocale] = useState<Locale>(currentLocale)
  const [translations, setTranslations] = useState<PhraseDictionary>(currentTranslations)

  useEffect(() => {
    const handler = (snapshot: TranslationSnapshot) => {
      setLocale(snapshot.locale)
      setTranslations(snapshot.translations)
    }

    listeners.add(handler)

    return () => {
      listeners.delete(handler)
    }
  }, [])

  useNuiEvent<SetTranslationsData>('setTranslations', (data) => {
    if (data && data.locale && data.translations) {
      setGlobalTranslations(data.locale, data.translations)
    }
  })

  useNuiEvent<SetLocaleData>('setLocale', (data) => {
    if (data && data.locale) {
      setGlobalLocale(data.locale)
    }
  })

  const t = useCallback((key: string, replacements?: Record<string, string | number>): string => {
    let text = translations[key] || key
    if (replacements) {
      Object.entries(replacements).forEach(([k, v]) => {
        text = text.replace(new RegExp(`{${k}}`, 'g'), String(v))
      })
    }
    return text
  }, [translations])

  return { t, locale, setLocale: setGlobalLocale }
}
