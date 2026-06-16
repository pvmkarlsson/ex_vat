// PDF-export med jsPDF + html2canvas.
// Bygger ett snyggt, fristående HTML-"dokument" av ENBART de valda delarna,
// renderar det till canvas och paginerar ut det på A4.
import jsPDF from 'jspdf'
import html2canvas from 'html2canvas'
import { TRIP, VERIFIED_DATE, ONWAY, CROATIA, ACTIVITIES, TIMELINE, NIGHTS, img } from '../data.js'
import { computeBudget, fmtSEK } from './budget.js'

const esc = (s) =>
  String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]))

const sleepName = (key) => {
  if (key === 'lh') return ONWAY.lh.name
  if (key === 'bw') return ONWAY.bw.name
  if (key === 'croatia') return 'Kroatien (valt boende)'
  return 'Hemma i Göteborg'
}

function buildReportHTML(state) {
  const { groups, total, selected } = computeBudget(state)
  const checked = ACTIVITIES.filter((a) => state.checkedActivities[a.id])

  const timelineRows = TIMELINE.map(
    (d) => `
      <tr>
        <td style="padding:6px 8px;border-bottom:1px solid #e7eaee;white-space:nowrap;color:#395d73;font-weight:600;">Dag ${d.day}</td>
        <td style="padding:6px 8px;border-bottom:1px solid #e7eaee;white-space:nowrap;color:#64748b;">${esc(d.date)}</td>
        <td style="padding:6px 8px;border-bottom:1px solid #e7eaee;">${esc(d.from)} → ${esc(d.to)}${d.distance ? ` · ~${d.distance} mil` : ''}</td>
        <td style="padding:6px 8px;border-bottom:1px solid #e7eaee;color:#64748b;">${esc(sleepName(d.sleep))}</td>
      </tr>`,
  ).join('')

  const activityRows =
    checked.length > 0
      ? checked
          .map(
            (a) => `<li style="margin:3px 0;">${esc(a.name)} <span style="color:#64748b;">— ${esc(a.town)}${
              a.currency === 'free' ? ' · gratis' : ` · ca ${a.price} ${a.currency}/pers`
            }</span></li>`,
          )
          .join('')
      : '<li style="color:#64748b;">Inga aktiviteter valda.</li>'

  const budgetRows = groups
    .map((g) => {
      const items = g.items
        .map(
          (i) => `
        <tr>
          <td style="padding:4px 8px;color:#334155;">${esc(i.label)}<div style="font-size:11px;color:#94a3b8;">${esc(i.detail)}</div></td>
          <td style="padding:4px 8px;text-align:right;white-space:nowrap;color:#334155;">${fmtSEK(i.sek)}</td>
        </tr>`,
        )
        .join('')
      return `
        <tr><td colspan="2" style="padding:10px 8px 2px;font-weight:700;color:#395d73;">${esc(g.label)}</td></tr>
        ${items}
        <tr><td style="padding:2px 8px 8px;text-align:right;color:#64748b;font-size:11px;">Delsumma</td>
            <td style="padding:2px 8px 8px;text-align:right;font-weight:600;border-bottom:1px solid #e7eaee;">${fmtSEK(g.sum)}</td></tr>`
    })
    .join('')

  const accImg = selected.image
    ? `<img src="${img(selected.image)}" crossorigin="anonymous" style="width:220px;height:140px;object-fit:cover;border-radius:8px;" />`
    : `<div style="width:220px;height:140px;border-radius:8px;background:linear-gradient(135deg,#90b3c2,#395d73);"></div>`

  return `
    <div style="font-family:Inter,Arial,sans-serif;color:#2c3946;width:760px;padding:32px;background:#ffffff;">
      <div style="border-bottom:3px solid #395d73;padding-bottom:12px;margin-bottom:16px;">
        <h1 style="margin:0;font-size:26px;color:#2c3946;">${esc(TRIP.title)}</h1>
        <p style="margin:4px 0 0;color:#64748b;font-size:14px;">${esc(TRIP.subtitle)}</p>
        <p style="margin:2px 0 0;color:#94a3b8;font-size:12px;">Genererad ${new Date().toLocaleDateString('sv-SE')} · data verifierad ${esc(VERIFIED_DATE)}</p>
      </div>

      <h2 style="font-size:17px;color:#395d73;margin:18px 0 6px;">Dag-för-dag</h2>
      <table style="width:100%;border-collapse:collapse;font-size:12px;">${timelineRows}</table>

      <h2 style="font-size:17px;color:#395d73;margin:22px 0 6px;">Valt boende i Kroatien</h2>
      <div style="display:flex;gap:16px;align-items:flex-start;">
        ${accImg}
        <div style="flex:1;">
          <div style="font-size:16px;font-weight:700;">${esc(selected.name)}</div>
          <div style="color:#64748b;font-size:13px;margin:2px 0 6px;">${esc(selected.town || '')}</div>
          <div style="font-size:13px;">${esc(selected.why)}</div>
          <div style="margin-top:8px;font-size:13px;color:#395d73;font-weight:600;">ca ${selected.pricePerNight} €/natt (${esc(selected.priceFlag)}) · ${NIGHTS.croatia} nätter</div>
          <div style="font-size:11px;color:#94a3b8;margin-top:2px;">${esc(selected.url)}</div>
        </div>
      </div>
      <p style="font-size:12px;color:#64748b;margin-top:10px;">
        På vägen: ${esc(ONWAY.lh.name)} (${NIGHTS.lh} nätter) och ${esc(ONWAY.bw.name)} (${NIGHTS.bw} nätter).
      </p>

      <h2 style="font-size:17px;color:#395d73;margin:22px 0 6px;">Valda aktiviteter</h2>
      <ul style="margin:0;padding-left:18px;font-size:13px;">${activityRows}</ul>

      <h2 style="font-size:17px;color:#395d73;margin:22px 0 6px;">Budget (SEK, tur och retur)</h2>
      <table style="width:100%;border-collapse:collapse;font-size:13px;">${budgetRows}</table>
      <div style="margin-top:12px;display:flex;justify-content:space-between;align-items:center;background:#395d73;color:#fff;padding:12px 16px;border-radius:8px;">
        <span style="font-size:15px;font-weight:600;">Total (t/r, 2 vuxna)</span>
        <span style="font-size:20px;font-weight:800;">${fmtSEK(total)}</span>
      </div>

      <p style="font-size:10px;color:#94a3b8;margin-top:18px;border-top:1px solid #e7eaee;padding-top:10px;">
        Priser, bilder och rutter är ungefärliga, hämtade ${esc(VERIFIED_DATE)}.
        Verifiera alltid aktuellt pris och tillgänglighet via länkarna innan bokning.
      </p>
    </div>`
}

export async function exportPDF(state) {
  const holder = document.createElement('div')
  holder.style.position = 'fixed'
  holder.style.left = '-10000px'
  holder.style.top = '0'
  holder.innerHTML = buildReportHTML(state)
  document.body.appendChild(holder)

  // Vänta in bilder så html2canvas hinner rita dem.
  const imgs = Array.from(holder.querySelectorAll('img'))
  await Promise.all(
    imgs.map(
      (im) =>
        im.complete
          ? Promise.resolve()
          : new Promise((res) => {
              im.onload = im.onerror = res
            }),
    ),
  )

  try {
    const canvas = await html2canvas(holder.firstElementChild, {
      scale: 2,
      useCORS: true,
      backgroundColor: '#ffffff',
      logging: false,
    })

    const pdf = new jsPDF({ unit: 'mm', format: 'a4', orientation: 'portrait' })
    const pageW = pdf.internal.pageSize.getWidth()
    const pageH = pdf.internal.pageSize.getHeight()
    const margin = 8
    const imgW = pageW - margin * 2
    const imgH = (canvas.height * imgW) / canvas.width

    let heightLeft = imgH
    let position = margin
    const dataUrl = canvas.toDataURL('image/jpeg', 0.92)

    pdf.addImage(dataUrl, 'JPEG', margin, position, imgW, imgH)
    heightLeft -= pageH - margin * 2

    while (heightLeft > 0) {
      position = margin - (imgH - heightLeft)
      pdf.addPage()
      pdf.addImage(dataUrl, 'JPEG', margin, position, imgW, imgH)
      heightLeft -= pageH - margin * 2
    }

    pdf.save(`resplan-split-2026-${new Date().toISOString().slice(0, 10)}.pdf`)
  } finally {
    holder.remove()
  }
}
