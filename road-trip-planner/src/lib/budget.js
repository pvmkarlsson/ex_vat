// Budgetberäkning – allt räknas om till SEK.
import { ONWAY, CROATIA, ACTIVITIES, NIGHTS, TRIP } from '../data.js'

export const toSEK = (amount, currency, rates) => {
  if (!amount || currency === 'free') return 0
  if (currency === 'EUR') return amount * rates.eur
  if (currency === 'DKK') return amount * rates.dkk
  return amount // antas redan vara SEK
}

export const fmtSEK = (n) =>
  new Intl.NumberFormat('sv-SE', { maximumFractionDigits: 0 }).format(Math.round(n || 0)) + ' kr'

export const fmtNum = (n, dec = 2) =>
  new Intl.NumberFormat('sv-SE', { maximumFractionDigits: dec }).format(n)

/**
 * Räknar fram alla budgetposter (SEK) utifrån aktuellt state.
 * Returnerar { groups, total } där varje grupp har { label, items[], sum }.
 */
export function computeBudget(state) {
  const { rates, fuel, bridges, vignettes, croatiaTolls, foodPerDay } = state

  // --- Bränsle (206 mil enkel × 2) ---
  const fuelLiters = fuel.distanceOneWay * 2 * fuel.consumption
  const fuelCost = fuelLiters * fuel.pricePerL

  // --- Boende på vägen ---
  const lhCost = NIGHTS.lh * ONWAY.lh.pricePerNight
  const bwCost = NIGHTS.bw * ONWAY.bw.pricePerNight

  // --- Boende Kroatien (valt kort) ---
  const selected = CROATIA.find((c) => c.id === state.selectedCroatiaId) || CROATIA[0]
  const croatiaCostEur = NIGHTS.croatia * selected.pricePerNight

  // --- Aktiviteter (ikryssade) ---
  const activityItems = ACTIVITIES.filter((a) => state.checkedActivities[a.id]).map((a) => ({
    label: a.name,
    detail: a.currency === 'free' ? 'gratis' : `${a.price} ${a.currency} · 2 pers`,
    // pris per person × 2 vuxna (gratis = 0)
    sek: toSEK(a.price, a.currency, rates) * (a.currency === 'free' ? 1 : 2),
  }))
  const activitiesSum = activityItems.reduce((s, i) => s + i.sek, 0)

  // --- Mat & dryck ---
  const foodCost = foodPerDay * TRIP.days

  const groups = [
    {
      key: 'transport',
      label: 'Transport',
      items: [
        {
          label: 'Bränsle (diesel)',
          detail: `${fuel.distanceOneWay} mil × 2 × ${fuel.consumption} L/mil × ${fuel.pricePerL} kr/L`,
          sek: fuelCost,
        },
        { label: 'Öresundsbron (t/r)', detail: 'fast avgift', sek: bridges.oresund },
        { label: 'Stora Bält (t/r)', detail: 'fast avgift', sek: bridges.storebalt },
        { label: 'Vinjett Österrike', detail: '10-dagars', sek: vignettes.austria },
        { label: 'Vinjett Slovenien', detail: '7-dagars', sek: vignettes.slovenia },
        { label: 'Kroatiska tullar (t/r)', detail: 'vägtullar', sek: croatiaTolls },
      ],
    },
    {
      key: 'boende',
      label: 'Boende',
      items: [
        {
          label: 'Lüneburger Heide',
          detail: `${NIGHTS.lh} nätter × ${ONWAY.lh.pricePerNight} € (ca)`,
          sek: toSEK(lhCost, 'EUR', rates),
        },
        {
          label: 'Bayerischer Wald',
          detail: `${NIGHTS.bw} nätter × ${ONWAY.bw.pricePerNight} € (ca)`,
          sek: toSEK(bwCost, 'EUR', rates),
        },
        {
          label: `Kroatien: ${selected.name}`,
          detail: `${NIGHTS.croatia} nätter × ${selected.pricePerNight} € (${selected.priceFlag})`,
          sek: toSEK(croatiaCostEur, 'EUR', rates),
        },
      ],
    },
    {
      key: 'aktiviteter',
      label: 'Aktiviteter',
      items:
        activityItems.length > 0
          ? activityItems
          : [{ label: 'Inga aktiviteter valda', detail: 'kryssa i kort för att lägga till', sek: 0 }],
    },
    {
      key: 'mat',
      label: 'Mat & dryck',
      items: [
        {
          label: 'Mat/dryck',
          detail: `${foodPerDay} kr/dag × ${TRIP.days} dagar`,
          sek: foodCost,
        },
      ],
    },
  ]

  groups.forEach((g) => {
    g.sum = g.items.reduce((s, i) => s + i.sek, 0)
  })

  const total = groups.reduce((s, g) => s + g.sum, 0)

  return { groups, total, selected, activitiesSum }
}
