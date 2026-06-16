import { ONWAY, CROATIA, NIGHTS, img } from '../data.js'
import SmartImage from './SmartImage.jsx'

function PriceTag({ value, currency, flag, suffix = '/natt' }) {
  const isEstimate = flag === 'uppskattad'
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold ${
        isEstimate ? 'bg-amber-100 text-amber-800' : 'bg-fjord-50 text-fjord-700'
      }`}
      title={isEstimate ? 'Uppskattat pris – verifiera via länken' : 'Ungefärligt pris'}
    >
      {isEstimate ? '≈' : 'ca'} {value} {currency === 'EUR' ? '€' : currency}
      {suffix}
      {isEstimate && <span className="font-normal">(uppskattad)</span>}
    </span>
  )
}

function OnwayCard({ place, nights }) {
  return (
    <div className="overflow-hidden rounded-xl border border-fjord-100 bg-white shadow-sm">
      <SmartImage
        src={img(place.image)}
        alt={place.name}
        label={place.name}
        className="h-32 w-full object-cover"
      />
      <div className="p-3">
        <div className="flex items-start justify-between gap-2">
          <h4 className="font-semibold text-fjord-900">{place.name}</h4>
          <PriceTag value={place.pricePerNight} currency={place.currency} flag={place.priceFlag} />
        </div>
        <p className="text-xs text-fjord-400">{place.town}</p>
        <p className="mt-1 text-sm text-fjord-500">{place.why}</p>
        <div className="mt-2 flex items-center justify-between">
          <span className="text-xs font-medium text-fjord-600">{nights} nätter (t/r)</span>
          <a
            href={place.url}
            target="_blank"
            rel="noreferrer"
            className="text-xs font-semibold text-fjord-600 underline-offset-2 hover:underline"
          >
            Boka ↗
          </a>
        </div>
      </div>
    </div>
  )
}

function CroatiaCard({ place, selected, onSelect }) {
  return (
    <button
      type="button"
      onClick={() => onSelect(place.id)}
      className={`group flex flex-col overflow-hidden rounded-xl border text-left shadow-sm transition focus:outline-none focus:ring-2 focus:ring-fjord-400 ${
        selected
          ? 'border-fjord-500 ring-2 ring-fjord-500'
          : 'border-fjord-100 hover:border-fjord-300'
      } bg-white`}
    >
      <div className="relative">
        <SmartImage
          src={place.image ? img(place.image) : null}
          alt={place.name}
          label={place.name}
          className="h-36 w-full object-cover"
        />
        <span
          className={`absolute right-2 top-2 flex h-6 w-6 items-center justify-center rounded-full text-sm font-bold shadow ${
            selected ? 'bg-fjord-600 text-white' : 'bg-white/90 text-fjord-300'
          }`}
        >
          {selected ? '✓' : ''}
        </span>
        {!place.hasShot && (
          <span className="absolute left-2 top-2 rounded bg-black/55 px-1.5 py-0.5 text-[10px] font-medium text-white">
            ingen skärmdump
          </span>
        )}
      </div>
      <div className="flex flex-1 flex-col p-3">
        <div className="flex items-start justify-between gap-2">
          <h4 className="font-semibold text-fjord-900">{place.name}</h4>
          <PriceTag value={place.pricePerNight} currency={place.currency} flag={place.priceFlag} />
        </div>
        <p className="text-xs text-fjord-400">{place.town}</p>
        <p className="mt-1 flex-1 text-sm text-fjord-500">{place.why}</p>
        <div className="mt-2 flex items-center justify-between">
          <span
            className={`text-xs font-semibold ${selected ? 'text-fjord-700' : 'text-fjord-400'}`}
          >
            {selected ? '✓ Valt boende' : 'Välj detta'}
          </span>
          <a
            href={place.url}
            target="_blank"
            rel="noreferrer"
            onClick={(e) => e.stopPropagation()}
            className="text-xs font-semibold text-fjord-600 underline-offset-2 hover:underline"
          >
            Boka ↗
          </a>
        </div>
      </div>
    </button>
  )
}

export default function AccommodationCards({ selectedCroatiaId, onSelectCroatia }) {
  return (
    <section id="boende" className="scroll-mt-4">
      <h2 className="mb-1 text-lg font-bold text-fjord-900">Boende på vägen</h2>
      <p className="mb-3 text-sm text-fjord-500">
        Små tält/skogscamping ned och hem – ingår automatiskt ({NIGHTS.lh + NIGHTS.bw} nätter totalt).
      </p>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <OnwayCard place={ONWAY.lh} nights={NIGHTS.lh} />
        <OnwayCard place={ONWAY.bw} nights={NIGHTS.bw} />
      </div>

      <h2 className="mb-1 mt-7 text-lg font-bold text-fjord-900">Boende i Kroatien</h2>
      <p className="mb-3 text-sm text-fjord-500">
        Välj ETT lyxigare boende för {NIGHTS.croatia} nätter i Split-trakten – budgeten uppdateras direkt.
      </p>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {CROATIA.map((place) => (
          <CroatiaCard
            key={place.id}
            place={place}
            selected={place.id === selectedCroatiaId}
            onSelect={onSelectCroatia}
          />
        ))}
      </div>
    </section>
  )
}
