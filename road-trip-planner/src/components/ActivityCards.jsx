import { ACTIVITIES, img } from '../data.js'
import SmartImage from './SmartImage.jsx'

const regionLabel = { vägen: 'På vägen', kroatien: 'I Kroatien' }

function ActivityCard({ act, checked, onToggle }) {
  const priceText =
    act.currency === 'free'
      ? 'Gratis'
      : `${act.priceFlag === 'uppskattad' ? '≈' : 'ca'} ${act.price} €/pers`

  return (
    <label
      className={`group flex cursor-pointer flex-col overflow-hidden rounded-xl border shadow-sm transition ${
        checked ? 'border-fjord-500 ring-2 ring-fjord-500' : 'border-fjord-100 hover:border-fjord-300'
      } bg-white`}
    >
      <div className="relative">
        <SmartImage
          src={act.image ? img(act.image) : null}
          alt={act.name}
          label={act.name}
          className="h-32 w-full object-cover"
        />
        <span className="absolute left-2 top-2 rounded bg-black/55 px-1.5 py-0.5 text-[10px] font-medium text-white">
          {regionLabel[act.region]}
        </span>
      </div>
      <div className="flex flex-1 flex-col p-3">
        <div className="flex items-start gap-2">
          <input
            type="checkbox"
            className="big-checkbox mt-0.5"
            checked={checked}
            onChange={() => onToggle(act.id)}
          />
          <div className="flex-1">
            <h4 className="font-semibold leading-tight text-fjord-900">{act.name}</h4>
            <p className="text-xs text-fjord-400">{act.town}</p>
          </div>
        </div>
        <p className="mt-2 flex-1 text-sm text-fjord-500">{act.why}</p>
        <div className="mt-2 flex items-center justify-between text-xs">
          <span className="font-semibold text-fjord-700">{priceText}</span>
          <span className="text-fjord-400">{act.hours}</span>
        </div>
        <div className="mt-1 flex items-center justify-between">
          {act.priceFlag === 'uppskattad' && act.currency !== 'free' ? (
            <span className="text-[10px] font-medium text-amber-700">uppskattat pris</span>
          ) : (
            <span />
          )}
          <a
            href={act.url}
            target="_blank"
            rel="noreferrer"
            onClick={(e) => e.stopPropagation()}
            className="text-xs font-semibold text-fjord-600 underline-offset-2 hover:underline"
          >
            Mer info ↗
          </a>
        </div>
      </div>
    </label>
  )
}

export default function ActivityCards({ checkedActivities, onToggle }) {
  return (
    <section id="aktiviteter" className="scroll-mt-4">
      <h2 className="mb-1 text-lg font-bold text-fjord-900">Aktiviteter</h2>
      <p className="mb-3 text-sm text-fjord-500">
        Kryssa i det ni vill göra – priserna (×2 vuxna) läggs direkt till budgeten.
      </p>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {ACTIVITIES.map((act) => (
          <ActivityCard
            key={act.id}
            act={act}
            checked={!!checkedActivities[act.id]}
            onToggle={onToggle}
          />
        ))}
      </div>
    </section>
  )
}
