import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

const VIRTUAL_ID = 'virtual:dev-translations'

function devTranslations(): Plugin {
  return {
    name: 'sxdoors-dev-translations',
    resolveId: (id) => (id === VIRTUAL_ID ? `\0${VIRTUAL_ID}` : null),
    load(id) {
      if (id !== `\0${VIRTUAL_ID}`) return null
      const languages: Record<string, Record<string, string>> = {}
      for (const lang of ['en', 'fr']) {
        const file = resolve(__dirname, `../translations/${lang}.lua`)
        this.addWatchFile(file)
        const phrases: Record<string, string> = {}
        for (const match of readFileSync(file, 'utf8').matchAll(/^\s*([a-z0-9_]+)\s*=\s*"((?:[^"\\]|\\.)*)"/gm)) {
          phrases[match[1]] = match[2].replace(/\\"/g, '"')
        }
        languages[lang] = phrases
      }
      return `export default ${JSON.stringify(languages)}`
    },
  }
}

export default defineConfig({
  plugins: [react(), tailwindcss(), devTranslations()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
})
