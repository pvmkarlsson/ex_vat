import { TIMELINE, ONWAY, CROATIA } from '../data.js'

const fmtDate = (iso) =>
  new Date(iso).toLocaleDateString('sv-SE', { day: 'numeric', month: 'short' })

export default function Timeline({ selectedCroatiaId }) {
  const selected = CROATIA.find((c) => c.id === selectedCroatiaId) || CROATIA[0]

  const sleepLabel = (key) => {
    if (key === 'lh') return ONWAY.lh.name
    if (key === 'bw') return ONWAY.bw.name
    if (key === 'croatia') return selected.name
    return 'Hemma i Göteborg'
  }

  return (
    <section id="tidslinje" className="scroll-mt-4">
      <h2 className="mb-3 text-lg font-bold text-fjord-900">Dag-för-dag · 14 dagar</h2>
      <ol className="relative border-l-2 border-fjord-100 pl-5">
        {TIMELINE.map((d) => (
          <li key={d.day} className="mb-4 last:mb-0">
            <span
              className={`absolute -left-[9px] mt-1 flex h-4 w-4 items-center justify-center rounded-full ring-4 ring-stone-50 ${
                d.kind === 'stay' ? 'bg-fjord-300' : 'bg-fjord-600'
              }`}
            />
            <div className="rounded-xl border border-fjord-100 bg-white p-3 shadow-sm">
              <div className="flex flex-wrap items-baseline justify-between gap-x-3">
                <span className="text-sm font-bold text-fjord-700">
                  Dag {d.day} · {fmtDate(d.date)}
                </span>
                {d.distance > 0 && (
                  <span className="rounded-full bg-fjord-50 px-2 py-0.5 text-xs font-medium text-fjord-600">
                    ~{d.distance} mil
                  </span>
                )}
              </div>
              <div className="mt-0.5 font-semibold text-fjord-900">
                {d.from === d.to ? d.from : `${d.from} → ${d.to}`}
              </div>
              <p className="mt-1 text-sm text-fjord-500">{d.note}</p>
              <p className="mt-1 text-xs text-fjord-400">🛌 {sleepLabel(d.sleep)}</p>
            </div>
          </li>
        ))}
      </ol>
    </section>
  )
}
