import { useMemo, useState } from 'react'
import { DEFAULTS, CROATIA } from './data.js'
import { fmtSEK, computeBudget } from './lib/budget.js'
import { exportJSON, importJSON } from './lib/jsonio.js'
import { exportPDF } from './lib/pdf.js'
import Header from './components/Header.jsx'
import Timeline from './components/Timeline.jsx'
import AccommodationCards from './components/AccommodationCards.jsx'
import ActivityCards from './components/ActivityCards.jsx'
import MapView from './components/MapView.jsx'
import BudgetPanel from './components/BudgetPanel.jsx'

const makeInitialState = () => ({
  rates: { ...DEFAULTS.rates },
  fuel: { ...DEFAULTS.fuel },
  bridges: { ...DEFAULTS.bridges },
  vignettes: { ...DEFAULTS.vignettes },
  croatiaTolls: DEFAULTS.croatiaTolls,
  foodPerDay: DEFAULTS.foodPerDay,
  selectedCroatiaId: CROATIA[0].id,
  // Förkryssade förslag så budgeten inte börjar tom.
  checkedActivities: { krka: true, diocletian: true, 'lh-lake': true },
})

// Säker sammanslagning vid import (behåller struktur även om filen är ofullständig).
const mergeImported = (incoming) => {
  const base = makeInitialState()
  return {
    rates: { ...base.rates, ...(incoming.rates || {}) },
    fuel: { ...base.fuel, ...(incoming.fuel || {}) },
    bridges: { ...base.bridges, ...(incoming.bridges || {}) },
    vignettes: { ...base.vignettes, ...(incoming.vignettes || {}) },
    croatiaTolls: incoming.croatiaTolls ?? base.croatiaTolls,
    foodPerDay: incoming.foodPerDay ?? base.foodPerDay,
    selectedCroatiaId: CROATIA.some((c) => c.id === incoming.selectedCroatiaId)
      ? incoming.selectedCroatiaId
      : base.selectedCroatiaId,
    checkedActivities: { ...(incoming.checkedActivities || {}) },
  }
}

export default function App() {
  const [state, setState] = useState(makeInitialState)
  const [mobileBudgetOpen, setMobileBudgetOpen] = useState(false)
  const [busy, setBusy] = useState(false)

  const { total } = useMemo(() => computeBudget(state), [state])

  const toggleActivity = (id) =>
    setState((s) => {
      const next = { ...s.checkedActivities }
      if (next[id]) delete next[id]
      else next[id] = true
      return { ...s, checkedActivities: next }
    })

  const handleImport = async (file) => {
    try {
      const incoming = await importJSON(file)
      setState(mergeImported(incoming))
    } catch (e) {
      alert('Kunde inte läsa filen: ' + e.message)
    }
  }

  const handlePDF = async () => {
    setBusy(true)
    try {
      await exportPDF(state)
    } catch (e) {
      alert('PDF-export misslyckades: ' + e.message)
    } finally {
      setBusy(false)
    }
  }

  const handleReset = () => {
    if (confirm('Återställ alla val till standard?')) setState(makeInitialState())
  }

  return (
    <div className="min-h-screen pb-20 lg:pb-0">
      <Header
        onExportJSON={() => exportJSON(state)}
        onImportJSON={handleImport}
        onExportPDF={handlePDF}
        onReset={handleReset}
      />

      <main className="mx-auto grid max-w-7xl grid-cols-1 gap-8 px-4 py-6 lg:grid-cols-[1fr_360px]">
        <div className="space-y-10">
          <Timeline selectedCroatiaId={state.selectedCroatiaId} />
          <MapView
            selectedCroatiaId={state.selectedCroatiaId}
            checkedActivities={state.checkedActivities}
          />
          <AccommodationCards
            selectedCroatiaId={state.selectedCroatiaId}
            onSelectCroatia={(id) => setState((s) => ({ ...s, selectedCroatiaId: id }))}
          />
          <ActivityCards checkedActivities={state.checkedActivities} onToggle={toggleActivity} />
        </div>

        {/* Sticky budget på desktop */}
        <aside className="hidden lg:block">
          <div className="sticky top-4">
            <BudgetPanel state={state} setState={setState} />
          </div>
        </aside>
      </main>

      {/* Mobil: sticky botten-bar + utfällbar panel */}
      <div className="fixed inset-x-0 bottom-0 z-[500] border-t border-fjord-100 bg-white/95 px-4 py-3 backdrop-blur lg:hidden">
        <div className="mx-auto flex max-w-7xl items-center justify-between">
          <div>
            <div className="text-[11px] uppercase tracking-wide text-fjord-400">Total t/r</div>
            <div className="text-xl font-extrabold text-fjord-800">{fmtSEK(total)}</div>
          </div>
          <button
            onClick={() => setMobileBudgetOpen(true)}
            className="rounded-lg bg-fjord-700 px-4 py-2 text-sm font-semibold text-white"
          >
            Visa budget
          </button>
        </div>
      </div>

      {mobileBudgetOpen && (
        <div className="fixed inset-0 z-[1000] flex flex-col bg-black/40 lg:hidden">
          <button className="flex-1" onClick={() => setMobileBudgetOpen(false)} aria-label="Stäng" />
          <div className="max-h-[88vh] overflow-hidden rounded-t-2xl bg-stone-50 p-3">
            <div className="mb-2 flex items-center justify-between">
              <span className="font-bold text-fjord-800">Budget</span>
              <button
                onClick={() => setMobileBudgetOpen(false)}
                className="rounded-md px-3 py-1 text-sm font-semibold text-fjord-600"
              >
                Stäng ✕
              </button>
            </div>
            <BudgetPanel state={state} setState={setState} />
          </div>
        </div>
      )}

      {busy && (
        <div className="fixed inset-0 z-[2000] flex items-center justify-center bg-black/30">
          <div className="rounded-xl bg-white px-6 py-4 font-semibold text-fjord-700 shadow-lg">
            Skapar PDF…
          </div>
        </div>
      )}

      <footer className="mx-auto max-w-7xl px-4 py-8 text-center text-xs text-fjord-400">
        Reseplanerare byggd med Vite, React, Tailwind, Leaflet/OpenStreetMap & jsPDF. Inga val sparas
        automatiskt – använd Exportera/Importera JSON för att behålla din plan mellan besök.
      </footer>
    </div>
  )
}
