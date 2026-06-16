import { useRef } from 'react'
import { TRIP, VERIFIED_DATE } from '../data.js'

export default function Header({ onExportJSON, onImportJSON, onExportPDF, onReset }) {
  const fileRef = useRef(null)

  return (
    <header className="border-b border-fjord-100 bg-white/80 backdrop-blur">
      {/* Disclaimer */}
      <div className="bg-fjord-800 px-4 py-2 text-center text-xs text-fjord-50 sm:text-sm">
        Priser, bilder och rutter är ungefärliga, hämtade {VERIFIED_DATE}. Verifiera alltid aktuellt
        pris och tillgänglighet via länkarna innan bokning.
      </div>

      <div className="mx-auto flex max-w-7xl flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-extrabold tracking-tight text-fjord-900 sm:text-2xl">
            🚐 {TRIP.title}
          </h1>
          <p className="text-sm text-fjord-500">{TRIP.subtitle}</p>
          <p className="mt-0.5 text-xs text-fjord-400">Senast verifierad: {VERIFIED_DATE}</p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={onExportPDF}
            className="rounded-lg bg-fjord-700 px-3 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-fjord-800"
          >
            ⬇︎ PDF
          </button>
          <button
            onClick={onExportJSON}
            className="rounded-lg border border-fjord-200 bg-white px-3 py-2 text-sm font-medium text-fjord-700 transition hover:bg-fjord-50"
          >
            Exportera JSON
          </button>
          <button
            onClick={() => fileRef.current?.click()}
            className="rounded-lg border border-fjord-200 bg-white px-3 py-2 text-sm font-medium text-fjord-700 transition hover:bg-fjord-50"
          >
            Importera JSON
          </button>
          <button
            onClick={onReset}
            title="Återställ alla val"
            className="rounded-lg border border-fjord-200 bg-white px-3 py-2 text-sm font-medium text-fjord-500 transition hover:bg-fjord-50"
          >
            Återställ
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="application/json"
            className="hidden"
            onChange={(e) => {
              if (e.target.files?.[0]) onImportJSON(e.target.files[0])
              e.target.value = ''
            }}
          />
        </div>
      </div>
    </header>
  )
}
