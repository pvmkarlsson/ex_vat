// =============================================================================
// RESEDATA – Göteborg ⇄ Split (Kroatien), 20 juli–2 augusti 2026
// -----------------------------------------------------------------------------
// Alla priser är ungefärliga ("ca") och hämtades/uppskattades 2026-06-16.
// Bilder är skärmdumpar tagna i steg 1 (se scripts/collect-data.mjs).
// Vissa kroatiska sajter gick inte att nå i datorns nätverksmiljö – de korten
// är märkta priceFlag: 'uppskattad' och saknar egen skärmdump (visar
// platshållare). Verifiera alltid via länken innan bokning.
// =============================================================================

export const VERIFIED_DATE = '2026-06-16'

export const TRIP = {
  title: 'Bilresa Göteborg → Split, Kroatien',
  subtitle: '20 juli – 2 augusti 2026 · 2 vuxna · Volvo V70 diesel',
  startDate: '2026-07-20',
  endDate: '2026-08-02',
  days: 14,
}

// Bildhjälpare – funkar både i dev och i byggd version (base: './').
export const img = (slug) => `${import.meta.env.BASE_URL}img/${slug}.jpg`

// -----------------------------------------------------------------------------
// ÖVERNATTNINGSPLATSER PÅ VÄGEN (tält, billigt, naturnära)
// -----------------------------------------------------------------------------
export const ONWAY = {
  lh: {
    id: 'lh',
    name: 'Camping-Park Lüneburger Heide',
    town: 'Heber/Soltau, Tyskland',
    why: 'Lummig hedcamping med egen badsjö – perfekt första dopp efter färjan/bron.',
    pricePerNight: 39, // EUR
    priceFlag: 'ca',
    currency: 'EUR',
    url: 'https://www.camping-lh.de/',
    image: 'lueneburger-heide',
    lat: 53.0667,
    lng: 9.815,
  },
  bw: {
    id: 'bw',
    name: 'Anderswo Camp – Bayerischer Wald',
    town: 'Lindberg, Tyskland',
    why: 'Avskalad naturcamping vid nationalparken med incheckning dygnet runt.',
    pricePerNight: 30, // EUR
    priceFlag: 'ca',
    currency: 'EUR',
    url: 'https://anderswo-camp.de/',
    image: 'bayerischer-wald',
    lat: 49.0667,
    lng: 13.2,
  },
}

// -----------------------------------------------------------------------------
// LYXIGARE CAMPING / GLAMPING I SPLIT-TRAKTEN (välj ETT som gäller)
// pricePerNight = riktpris högsäsong för bungalow/mobilhome/glamping (EUR/natt).
// -----------------------------------------------------------------------------
export const CROATIA = [
  {
    id: 'stobrec',
    name: 'Camping Stobreč Split',
    town: 'Stobreč (6 km från Splits gamla stan)',
    why: 'Fyrstjärnig strandcamping med pool, wellness och egen halvö – stan på cykelavstånd.',
    pricePerNight: 95,
    priceFlag: 'ca',
    currency: 'EUR',
    url: 'https://www.campingsplit.com/',
    image: 'stobrec',
    hasShot: true,
    lat: 43.506,
    lng: 16.526,
  },
  {
    id: 'glamping-dalmatia',
    name: 'Glamping Luxury Tents (Dalmatien)',
    town: 'Pakoštane (~1 h norr om Split)',
    why: 'Safari-glampingtält med havsutsikt mellan Krka och Kornati – riktig glampingkänsla.',
    pricePerNight: 120,
    priceFlag: 'ca',
    currency: 'EUR',
    url: 'https://www.glamping-croatia.com/',
    image: 'glamping-croatia',
    hasShot: true,
    lat: 43.906,
    lng: 15.512,
  },
  {
    id: 'belvedere-trogir',
    name: 'Camping Belvedere Trogir',
    town: 'Seget Vranjica (nära Trogir)',
    why: 'Mobilhome och bungalower med pool vid havet, väster om Split nära Trogirs gamla stan.',
    pricePerNight: 110,
    priceFlag: 'uppskattad',
    currency: 'EUR',
    url: 'https://www.camping-belvedere.hr/',
    image: null, // sajten gick inte att nå för skärmdump
    hasShot: false,
    lat: 43.518,
    lng: 16.205,
  },
  {
    id: 'galeb-omis',
    name: 'Camping Galeb Omiš',
    town: 'Omiš (~25 km söder om Split)',
    why: 'Premium-mobilhomes och pool vid stranden där floden Cetina möter havet – bra för utflykter.',
    pricePerNight: 115,
    priceFlag: 'uppskattad',
    currency: 'EUR',
    url: 'https://www.camp-galeb.hr/',
    image: null,
    hasShot: false,
    lat: 43.444,
    lng: 16.681,
  },
  {
    id: 'krka-skradin',
    name: 'Camping Krka, Skradin',
    why: 'Lugn campingby intill Krka nationalpark med bungalower – nära vattenfall och båtbrygga.',
    town: 'Skradin (port till Krka NP)',
    pricePerNight: 90,
    priceFlag: 'uppskattad',
    currency: 'EUR',
    url: 'https://www.campingkrka.com/',
    image: null,
    hasShot: false,
    lat: 43.821,
    lng: 15.922,
  },
  {
    id: 'solitudo',
    name: 'Camping Solitudo',
    town: 'Dubrovnik (lång utflykt söderut)',
    why: 'Skuggig camping nära Dubrovniks gamla stan – välj om ni vill kombinera Split med Dubrovnik.',
    pricePerNight: 80,
    priceFlag: 'uppskattad',
    currency: 'EUR',
    url: 'https://www.camping-solitudo.com/',
    image: null,
    hasShot: false,
    lat: 42.658,
    lng: 18.07,
  },
]

// -----------------------------------------------------------------------------
// AKTIVITETER (kryssbara – uppdaterar budgeten direkt)
// price i 'currency'; currency 'EUR' | 'SEK' | 'free'.
// -----------------------------------------------------------------------------
export const ACTIVITIES = [
  {
    id: 'krka',
    name: 'Krka nationalpark',
    town: 'Skradin / Lozovac',
    why: 'Forsande vattenfall och träspångar genom kanjonen – en av Kroatiens vackraste parker.',
    price: 40,
    priceFlag: 'ca',
    currency: 'EUR',
    hours: 'ca 08–19 (sommar)',
    url: 'https://www.npkrka.hr/',
    image: 'krka-np',
    hasShot: true,
    lat: 43.805,
    lng: 15.971,
    region: 'kroatien',
  },
  {
    id: 'plitvice',
    name: 'Plitvice nationalpark',
    town: 'På vägen Zagreb–Split',
    why: '16 turkosa sjöar förbundna med vattenfall och kilometervis av träspänger.',
    price: 40,
    priceFlag: 'ca',
    currency: 'EUR',
    hours: 'ca 07–20 (sommar)',
    url: 'https://np-plitvicka-jezera.hr/en/',
    image: 'plitvice',
    hasShot: true,
    lat: 44.8654,
    lng: 15.582,
    region: 'vägen',
  },
  {
    id: 'biokovo',
    name: 'Biokovo Skywalk',
    town: 'Naturpark Biokovo, Makarska',
    why: 'Glasplattform 1228 m över Adriatiska havet – svindlande utsikt över kusten och öarna.',
    price: 20,
    priceFlag: 'ca',
    currency: 'EUR',
    hours: 'tidsbokad bilväg upp, ca 06–18',
    url: 'https://pp-biokovo.hr/en/',
    image: 'biokovo',
    hasShot: true,
    lat: 43.317,
    lng: 17.053,
    region: 'kroatien',
  },
  {
    id: 'diocletian',
    name: 'Diocletianus palats',
    town: 'Split gamla stan',
    why: 'Romerskt kejsarpalats som är Splits levande gamla stan – gratis att vandra, källare & katedral mot entré.',
    price: 10,
    priceFlag: 'ca',
    currency: 'EUR',
    hours: 'gränderna alltid öppna; källare ca 09–20',
    url: 'https://visitsplit.com/',
    image: 'diocletian',
    hasShot: true,
    lat: 43.5081,
    lng: 16.4402,
    region: 'kroatien',
  },
  {
    id: 'hvar-brac',
    name: 'Ö-dagstur Hvar / Brač',
    town: 'Båt från Split',
    why: 'Heldagstur till lavendelön Hvar och strandtungan Zlatni Rat på Brač.',
    price: 70,
    priceFlag: 'uppskattad',
    currency: 'EUR',
    hours: 'heldag (ca 09–18)',
    url: 'https://www.visithvar.hr/en/',
    image: 'hvar-brac',
    hasShot: true,
    lat: 43.1729,
    lng: 16.4413,
    region: 'kroatien',
  },
  {
    id: 'lh-lake',
    name: 'Bad i Lüneburger Heides badsjö',
    town: 'Camping-Park Lüneburger Heide',
    why: 'Svalkande dopp i campingens egen badsjö direkt vid tältet.',
    price: 0,
    priceFlag: 'ca',
    currency: 'free',
    hours: 'dagsljus',
    url: 'https://www.camping-lh.de/',
    image: 'lueneburger-heide',
    hasShot: true,
    lat: 53.0667,
    lng: 9.815,
    region: 'vägen',
  },
  {
    id: 'bw-trail',
    name: 'Vandring i Bayerischer Wald NP',
    town: 'Nationalpark Bayerischer Wald',
    why: 'Urskogsleder och trädtoppsstig (Baumwipfelpfad) i Tysklands äldsta nationalpark.',
    price: 12,
    priceFlag: 'uppskattad',
    currency: 'EUR',
    hours: 'leder dygnet runt; trädtoppsstig ca 09:30–18',
    url: 'https://anderswo-camp.de/',
    image: 'bayerischer-wald',
    hasShot: true,
    lat: 49.0667,
    lng: 13.2,
    region: 'vägen',
  },
]

// -----------------------------------------------------------------------------
// RUTT & TIDSLINJE (14 dagar). nights = vilken plats man sover på = 'lh'|'bw'|'croatia'|null
// -----------------------------------------------------------------------------
export const WAYPOINTS = {
  goteborg: { name: 'Göteborg', lat: 57.7089, lng: 11.9746 },
  split: { name: 'Split-trakten', lat: 43.5081, lng: 16.4402 },
}

export const TIMELINE = [
  { day: 1, date: '2026-07-20', from: 'Göteborg', to: 'Lüneburger Heide', distance: 60, sleep: 'lh', kind: 'drive',
    note: 'Avresa norrut: Öresundsbron, Stora Bält och ner genom Tyskland till heden.' },
  { day: 2, date: '2026-07-21', from: 'Lüneburger Heide', to: 'Bayerischer Wald', distance: 55, sleep: 'bw', kind: 'drive',
    note: 'Genom Tyskland till nationalparken vid tjeckiska gränsen.' },
  { day: 3, date: '2026-07-22', from: 'Bayerischer Wald', to: 'Split-trakten', distance: 70, sleep: 'croatia', kind: 'drive',
    note: 'Österrike (vinjett) och Slovenien (vinjett) till kroatiska kusten.' },
  { day: 4, date: '2026-07-23', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Landa i basläger – strand, pool och Splits gamla stan.' },
  { day: 5, date: '2026-07-24', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Utflyktsdag (t.ex. Krka eller Biokovo).' },
  { day: 6, date: '2026-07-25', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Strand- och stadsdag i Split.' },
  { day: 7, date: '2026-07-26', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Ö-dagstur till Hvar/Brač.' },
  { day: 8, date: '2026-07-27', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Lugn dag vid boendet.' },
  { day: 9, date: '2026-07-28', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Utflykt eller vinprovning i inlandet.' },
  { day: 10, date: '2026-07-29', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Strand och bad.' },
  { day: 11, date: '2026-07-30', from: 'Split-trakten', to: 'Split-trakten', distance: 0, sleep: 'croatia', kind: 'stay',
    note: 'Sista dagen i Kroatien – packa och njut.' },
  { day: 12, date: '2026-07-31', from: 'Split-trakten', to: 'Bayerischer Wald', distance: 70, sleep: 'bw', kind: 'drive',
    note: 'Hemresa börjar – spegelvänd rutt genom Slovenien och Österrike.' },
  { day: 13, date: '2026-08-01', from: 'Bayerischer Wald', to: 'Lüneburger Heide', distance: 55, sleep: 'lh', kind: 'drive',
    note: 'Norrut genom Tyskland, sista campingnatt vid heden.' },
  { day: 14, date: '2026-08-02', from: 'Lüneburger Heide', to: 'Göteborg', distance: 60, sleep: null, kind: 'drive',
    note: 'Sista etappen hem över broarna till Göteborg.' },
]

// Antal nätter per boendetyp (härleds av tidslinjen).
export const NIGHTS = TIMELINE.reduce(
  (acc, d) => {
    if (d.sleep === 'lh') acc.lh += 1
    else if (d.sleep === 'bw') acc.bw += 1
    else if (d.sleep === 'croatia') acc.croatia += 1
    return acc
  },
  { lh: 0, bw: 0, croatia: 0 },
)

// -----------------------------------------------------------------------------
// BUDGET – standardvärden (allt redigerbart i appen). Belopp i SEK om inget annat.
// -----------------------------------------------------------------------------
export const DEFAULTS = {
  rates: { eur: 11.3, dkk: 1.55 }, // SEK per EUR / DKK
  fuel: {
    distanceOneWay: 206, // mil (enkel resa), räknas ×2
    consumption: 0.575, // L/mil
    pricePerL: 18, // kr/L
  },
  bridges: {
    oresund: 1460, // kr, t/r
    storebalt: 840, // kr, t/r
  },
  vignettes: {
    austria: 140, // kr (10-dagars)
    slovenia: 180, // kr (7-dagars)
  },
  croatiaTolls: 570, // kr, t/r
  foodPerDay: 500, // kr/dygn för 2 vuxna (redigerbart)
}
