// Exportera/importera valen till fil (INGEN localStorage – state hålls i minnet).
import { VERIFIED_DATE } from '../data.js'

export function exportJSON(state) {
  const payload = {
    _typ: 'reseplanerare-goteborg-split',
    _version: 1,
    _exporterad: new Date().toISOString(),
    _dataVerifierad: VERIFIED_DATE,
    state,
  }
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `resplan-split-2026-${new Date().toISOString().slice(0, 10)}.json`
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}

export function importJSON(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      try {
        const parsed = JSON.parse(reader.result)
        const state = parsed.state ?? parsed
        if (!state || typeof state !== 'object') throw new Error('Ogiltigt format')
        resolve(state)
      } catch (e) {
        reject(e)
      }
    }
    reader.onerror = () => reject(reader.error)
    reader.readAsText(file)
  })
}
