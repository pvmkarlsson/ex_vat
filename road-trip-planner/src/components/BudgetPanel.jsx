import { useState } from 'react'
import { computeBudget, fmtSEK } from '../lib/budget.js'

function Num({ value, onChange, step = '1', suffix }) {
  return (
    <span className="inline-flex items-center gap-1">
      <input
        type="number"
        step={step}
        value={value}
        onChange={(e) => onChange(e.target.value === '' ? 0 : Number(e.target.value))}
        className="w-20 rounded-md border border-fjord-200 px-2 py-1 text-right text-sm focus:border-fjord-400 focus:outline-none focus:ring-1 focus:ring-fjord-400"
      />
      {suffix && <span className="text-xs text-fjord-400">{suffix}</span>}
    </span>
  )
}

function Field({ label, children }) {
  return (
    <label className="flex items-center justify-between gap-2 py-1 text-sm text-fjord-600">
      <span>{label}</span>
      {children}
    </label>
  )
}

export default function BudgetPanel({ state, setState }) {
  const [showSettings, setShowSettings] = useState(false)
  const { groups, total } = computeBudget(state)

  // Hjälpare för att uppdatera nästlade fält utan localStorage – allt i minnet.
  const set = (patch) => setState((s) => ({ ...s, ...patch }))
  const setIn = (key, patch) => setState((s) => ({ ...s, [key]: { ...s[key], ...patch } }))

  return (
    <div className="flex max-h-[calc(100vh-2rem)] flex-col rounded-2xl border border-fjord-100 bg-white shadow-md">
      <div className="rounded-t-2xl bg-fjord-700 px-4 py-3 text-white">
        <div className="text-xs uppercase tracking-wide text-fjord-100/80">Total t/r · 2 vuxna</div>
        <div className="text-3xl font-extrabold leading-tight">{fmtSEK(total)}</div>
      </div>

      <div className="thin-scroll flex-1 overflow-y-auto px-4 py-3">
        {groups.map((g) => (
          <div key={g.key} className="mb-3">
            <div className="mb-1 flex items-baseline justify-between">
              <h3 className="text-sm font-bold text-fjord-800">{g.label}</h3>
              <span className="text-sm font-semibold text-fjord-700">{fmtSEK(g.sum)}</span>
            </div>
            <ul className="space-y-0.5">
              {g.items.map((i, idx) => (
                <li key={idx} className="flex items-start justify-between gap-2 text-xs">
                  <span className="text-fjord-500">
                    {i.label}
                    {i.detail && <span className="block text-[10px] text-fjord-300">{i.detail}</span>}
                  </span>
                  <span className="whitespace-nowrap font-medium text-fjord-600">{fmtSEK(i.sek)}</span>
                </li>
              ))}
            </ul>
          </div>
        ))}

        {/* Inställningar (redigerbara antaganden) */}
        <button
          onClick={() => setShowSettings((v) => !v)}
          className="mt-1 w-full rounded-lg bg-fjord-50 px-3 py-2 text-sm font-semibold text-fjord-700 transition hover:bg-fjord-100"
        >
          {showSettings ? '▲ Dölj antaganden' : '▼ Redigera antaganden'}
        </button>

        {showSettings && (
          <div className="mt-2 space-y-1 rounded-lg border border-fjord-100 p-3">
            <p className="pb-1 text-[11px] font-semibold uppercase tracking-wide text-fjord-400">
              Bränsle
            </p>
            <Field label="Förbrukning">
              <Num
                value={state.fuel.consumption}
                step="0.005"
                suffix="L/mil"
                onChange={(v) => setIn('fuel', { consumption: v })}
              />
            </Field>
            <Field label="Dieselpris">
              <Num
                value={state.fuel.pricePerL}
                step="0.1"
                suffix="kr/L"
                onChange={(v) => setIn('fuel', { pricePerL: v })}
              />
            </Field>
            <Field label="Sträcka (enkel)">
              <Num
                value={state.fuel.distanceOneWay}
                suffix="mil"
                onChange={(v) => setIn('fuel', { distanceOneWay: v })}
              />
            </Field>

            <p className="pb-1 pt-2 text-[11px] font-semibold uppercase tracking-wide text-fjord-400">
              Broar, vinjetter & tullar (kr)
            </p>
            <Field label="Öresundsbron t/r">
              <Num value={state.bridges.oresund} onChange={(v) => setIn('bridges', { oresund: v })} />
            </Field>
            <Field label="Stora Bält t/r">
              <Num value={state.bridges.storebalt} onChange={(v) => setIn('bridges', { storebalt: v })} />
            </Field>
            <Field label="Vinjett Österrike">
              <Num value={state.vignettes.austria} onChange={(v) => setIn('vignettes', { austria: v })} />
            </Field>
            <Field label="Vinjett Slovenien">
              <Num value={state.vignettes.slovenia} onChange={(v) => setIn('vignettes', { slovenia: v })} />
            </Field>
            <Field label="Kroatiska tullar t/r">
              <Num value={state.croatiaTolls} onChange={(v) => set({ croatiaTolls: v })} />
            </Field>

            <p className="pb-1 pt-2 text-[11px] font-semibold uppercase tracking-wide text-fjord-400">
              Mat & växelkurser
            </p>
            <Field label="Mat/dryck per dag">
              <Num value={state.foodPerDay} suffix="kr" onChange={(v) => set({ foodPerDay: v })} />
            </Field>
            <Field label="Växelkurs SEK/EUR">
              <Num value={state.rates.eur} step="0.01" onChange={(v) => setIn('rates', { eur: v })} />
            </Field>
            <Field label="Växelkurs SEK/DKK">
              <Num value={state.rates.dkk} step="0.01" onChange={(v) => setIn('rates', { dkk: v })} />
            </Field>
          </div>
        )}
      </div>

      <div className="flex items-center justify-between rounded-b-2xl border-t border-fjord-100 bg-fjord-50 px-4 py-3">
        <span className="text-sm font-semibold text-fjord-700">Total t/r</span>
        <span className="text-xl font-extrabold text-fjord-800">{fmtSEK(total)}</span>
      </div>
    </div>
  )
}
