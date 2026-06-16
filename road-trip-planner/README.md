# 🚐 Reseplanerare · Göteborg → Split, Kroatien (2026)

Interaktiv reseplanerare för en bilresa tur och retur **Göteborg → Split-trakten,
Kroatien → Göteborg**, 20 juli–2 augusti 2026, 2 vuxna, Volvo V70 diesel.

Byggd med **Vite + React + Tailwind CSS**, karta med **Leaflet + OpenStreetMap**
(ingen API-nyckel) och PDF-export med **jsPDF + html2canvas**.

> **Disclaimer:** Priser, bilder och rutter är ungefärliga, hämtade **2026-06-16**.
> Verifiera alltid aktuellt pris och tillgänglighet via länkarna innan bokning.

---

## Komma igång

```bash
cd road-trip-planner
npm install
npm run dev          # startar Vite dev-server (http://localhost:5173)
```

Bygga för produktion / förhandsgranska:

```bash
npm run build
npm run preview      # serverar dist/ på http://localhost:4173
```

---

## Funktioner

1. **Dag-för-dag-tidslinje (14 dagar)** med rutt, etapplängder (~mil) och
   övernattningar. Dag 1 Göteborg→Lüneburger Heide · Dag 2 →Bayerischer Wald ·
   Dag 3 →Kroatien · Dag 4–11 Split-trakten · Dag 12–14 spegelvänd hemresa.
2. **Kryssbara boende- och aktivitetskort** med de insamlade bilderna. I-/
   urkryssning uppdaterar budgeten direkt. Du väljer vilket Kroatien-boende som gäller.
3. **Karta** (Leaflet/OpenStreetMap) med streckad rutt och markörer för
   övernattningar och aktiviteter (valda aktiviteter markeras tydligt).
4. **Live budgetpanel** (sticky, alltid synlig) som räknar om direkt:
   bränsle (206 mil enkel × 2, redigerbar förbrukning & dieselpris), broar
   (Öresund + Stora Bält), vinjetter (Österrike + Slovenien), kroatiska tullar,
   camping på vägen, valt Kroatien-boende, ikryssade aktiviteter och redigerbar
   mat/dryck per dag. Allt i **SEK** med redigerbar växelkurs SEK/EUR (11,3) och
   SEK/DKK (1,55). Visar delsummor + total t/r.
5. **PDF-export** – en knapp genererar en snygg PDF med rubrik + datum,
   dag-för-dag-plan, valt boende (med bild), ikryssade aktiviteter och full
   budgetuppställning. Endast det valda kommer med.
6. **Exportera / Importera JSON** – spara dina val till fil och läs in dem igen.
   Appen använder **inte** localStorage; allt state hålls i minnet under sessionen.

---

## Steg 1 – Datainsamlingen (Chrome / Playwright)

Bilderna i `public/img/` är skärmdumpar tagna automatiskt med **Playwright +
Chromium** (motsvarar browser-/Chrome-MCP-steget). Skriptet besöker camping- och
aktivitetssidor, försöker läsa riktpriser och sparar skärmdumpar.

Kör om datainsamlingen så här:

```bash
npx playwright install chromium   # första gången – laddar ner Chromium
npm run collect-data              # kör scripts/collect-data.mjs
```

Resultat:

- `public/img/<slug>.jpg` – en hero-bild (+ `-2.jpg` en bit ned på sidan) per ställe.
- `public/img/_pris-logg.txt` – rådata med pris-träffar för manuell koll.

### Anpassa vilka sidor som besöks

Redigera listan `TARGETS` överst i [`scripts/collect-data.mjs`](scripts/collect-data.mjs)
(`{ slug, url, label }`) och lägg till priser/koordinater i
[`src/data.js`](src/data.js).

### Noteringar om datakvalitet

- Alla priser visas som **"ca"**. Där en sida inte gick att nå eller saknade
  pris är posten flaggad som **"uppskattad"** i appen och i `src/data.js`.
- I den miljö datan samlades in var utgående trafik allowlist-begränsad. Flera
  kroatiska campingsajter (t.ex. `camping-belvedere.hr`, `camp-galeb.hr`,
  `campingkrka.com`, `camping-solitudo.com`) gick **inte** att nå för skärmdump.
  De korten har riktiga boknings-URL:er och uppskattade priser men visar en
  stilren platshållare i stället för skärmdump. Kör om `collect-data` från ett
  öppnare nät för att fylla i dem.
- Proxyn i insamlingsmiljön gör TLS-MITM, därför startas Chromium med
  `--ignore-certificate-errors` / `ignoreHTTPSErrors` i skriptet. Detta behövs
  normalt inte på en vanlig dator – ta bort flaggorna om du vill.

---

## Projektstruktur

```
road-trip-planner/
├─ public/img/                 # skärmdumpar (steg 1) + pris-logg
├─ scripts/collect-data.mjs    # Playwright-datainsamling (steg 1)
├─ src/
│  ├─ data.js                  # all resedata (rutt, boenden, aktiviteter, priser)
│  ├─ App.jsx                  # state + layout
│  ├─ components/              # Header, Timeline, kort, MapView, BudgetPanel ...
│  └─ lib/                     # budget, pdf, json import/export
└─ ...
```

## Teknik

Vite · React 18 · Tailwind CSS 3 · Leaflet / react-leaflet · jsPDF · html2canvas ·
Playwright (datainsamling).
