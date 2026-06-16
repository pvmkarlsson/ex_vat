/**
 * STEG 1 – DATAINSAMLING MED CHROME (Playwright/Chromium)
 * ------------------------------------------------------------------
 * Besöker camping-, glamping- och aktivitetssidor, försöker läsa
 * ungefärliga priser och SPARAR SCREENSHOTS till /public/img/.
 *
 * Målet är ATMOSFÄR + RIKTPRISER, inte exakt tillgänglighet – vi
 * navigerar alltså INTE bokningskalendrar för specifika datum.
 *
 * Kör:  npm run collect-data
 *
 * Resultat:
 *   - public/img/<slug>.jpg     (en eller flera bilder per ställe)
 *   - public/img/_pris-logg.txt (rådata med pris-träffar för manuell koll)
 *
 * Allt som hämtas ska behandlas som "ca"-priser. Om en sida blockerar
 * eller saknar pris: gör en rimlig uppskattning i src/data.js och
 * flagga den som "uppskattad".
 */
import { chromium } from 'playwright'
import { mkdir, appendFile, writeFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const __dirname = dirname(fileURLToPath(import.meta.url))
const IMG_DIR = join(__dirname, '..', 'public', 'img')
const LOG_FILE = join(IMG_DIR, '_pris-logg.txt')

// Varje target: { slug, url, label }
// OBS: I detta körmiljö är utgående trafik allowlist-styrd. Domäner som inte
// gick att nå (camping-belvedere.hr, camp-galeb.hr, amberglamping.com,
// campingkrka.com, baumwipfelpfad-neuschoenau.de) är ersatta med nåbara
// alternativ eller hanteras med uppskattat pris + platshållarbild i data.js.
const TARGETS = [
  // --- Boende på vägen ---
  { slug: 'lueneburger-heide', url: 'https://www.camping-lh.de/', label: 'Camping-Park Lüneburger Heide' },
  { slug: 'bayerischer-wald', url: 'https://anderswo-camp.de/', label: 'Anderswo Camp Bayerischer Wald' },

  // --- Lyxigare camping / glamping i Split-trakten (nåbara sajter) ---
  { slug: 'stobrec', url: 'https://www.campingsplit.com/', label: 'Camping Stobreč Split' },
  { slug: 'belvedere-trogir', url: 'https://www.campingbelvedere.com/', label: 'Camping Belvedere Trogir' },

  // --- Aktiviteter ---
  { slug: 'krka-np', url: 'https://www.npkrka.hr/en_US/', label: 'Krka nationalpark' },
  { slug: 'plitvice', url: 'https://np-plitvicka-jezera.hr/en/', label: 'Plitvice nationalpark' },
  { slug: 'biokovo', url: 'https://pp-biokovo.hr/en/', label: 'Biokovo naturpark / Skywalk' },
  { slug: 'diocletian', url: 'https://visitsplit.com/en/1/welcome-to-split', label: 'Diocletianus palats, Split' },
  { slug: 'hvar-brac', url: 'https://www.visithvar.hr/en/', label: 'Ö-dagstur Hvar / Brač' },
]

// Vanliga cookie-/samtyckesknappar (flera språk).
const CONSENT_TEXTS = [
  'Accept all', 'Accept All', 'Akzeptieren', 'Alle akzeptieren', 'I agree',
  'Godkänn', 'Tillåt alla', 'Prihvati', 'Prihvaćam', 'Slažem se',
  'Accept', 'Zustimmen', 'OK', 'Got it', 'Allow all', 'Agree',
]

async function dismissConsent(page) {
  for (const text of CONSENT_TEXTS) {
    try {
      const btn = page.getByRole('button', { name: text, exact: false }).first()
      if (await btn.isVisible({ timeout: 500 })) {
        await btn.click({ timeout: 1500 })
        await page.waitForTimeout(400)
        return
      }
    } catch { /* nästa */ }
  }
}

// Letar efter pris-liknande textsnuttar (€, EUR, kn, kr, HRK) på sidan.
async function grabPrices(page) {
  try {
    const text = await page.evaluate(() => document.body.innerText || '')
    const lines = text.split('\n').map((l) => l.trim()).filter(Boolean)
    const hits = lines.filter((l) =>
      /(€|EUR|\bkn\b|HRK|\bkr\b|night|natt|Nacht|noć|person|adult|erwachsene)/i.test(l) &&
      /\d/.test(l) && l.length < 120,
    )
    return [...new Set(hits)].slice(0, 25)
  } catch {
    return []
  }
}

async function run() {
  await mkdir(IMG_DIR, { recursive: true })
  const stamp = new Date().toISOString()
  await writeFile(LOG_FILE, `Prislogg – datainsamling ${stamp}\n${'='.repeat(60)}\n\n`)

  // --ignore-certificate-errors krävs eftersom miljöns proxy gör TLS-MITM med
  // en CA som Chromium inte litar på i grunden.
  const browser = await chromium.launch({ args: ['--ignore-certificate-errors'] })
  const ctx = await browser.newContext({
    viewport: { width: 1366, height: 900 },
    userAgent:
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
    locale: 'en-US',
    ignoreHTTPSErrors: true,
  })
  const page = await ctx.newPage()

  for (const t of TARGETS) {
    const line = `\n### ${t.label}  (${t.slug})\n${t.url}\n`
    process.stdout.write(line)
    try {
      await page.goto(t.url, { waitUntil: 'domcontentloaded', timeout: 30000 })
      await page.waitForTimeout(2500)
      await dismissConsent(page)
      await page.waitForTimeout(800)

      // Hero-bild: skärmdump av första vyn.
      const out = join(IMG_DIR, `${t.slug}.jpg`)
      await page.screenshot({ path: out, type: 'jpeg', quality: 80 })

      // En extra bild en bit ned på sidan för mer atmosfär.
      await page.evaluate(() => window.scrollTo(0, Math.round(window.innerHeight * 1.4)))
      await page.waitForTimeout(1200)
      await page.screenshot({ path: join(IMG_DIR, `${t.slug}-2.jpg`), type: 'jpeg', quality: 80 })

      const prices = await grabPrices(page)
      await appendFile(LOG_FILE, `${line}OK – screenshot sparad: ${t.slug}.jpg\nPris-träffar:\n  ${prices.join('\n  ') || '(inga – uppskatta i data.js)'}\n`)
      process.stdout.write(`  ✓ sparad ${t.slug}.jpg  (${prices.length} pris-träffar)\n`)
    } catch (err) {
      await appendFile(LOG_FILE, `${line}MISSLYCKADES: ${err.message}\n  -> använd uppskattat pris + reservbild i data.js\n`)
      process.stdout.write(`  ✗ ${t.slug}: ${err.message}\n`)
    }
  }

  await browser.close()
  process.stdout.write(`\nKlart. Se ${LOG_FILE} för pris-loggen.\n`)
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
