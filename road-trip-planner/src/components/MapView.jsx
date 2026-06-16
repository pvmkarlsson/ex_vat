import { useMemo } from 'react'
import { MapContainer, TileLayer, Marker, Polyline, Popup, useMap } from 'react-leaflet'
import L from 'leaflet'
import { WAYPOINTS, ONWAY, CROATIA, ACTIVITIES } from '../data.js'

// Egna markörer (divIcon) så vi slipper Leaflets standardikon-asset i Vite.
const pin = (color, glyph) =>
  L.divIcon({
    className: 'rtp-pin',
    html: `<div style="background:${color};width:26px;height:26px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);
            box-shadow:0 1px 4px rgba(0,0,0,.4);display:flex;align-items:center;justify-content:center;border:2px solid #fff;">
            <span style="transform:rotate(45deg);font-size:13px;line-height:1;">${glyph}</span></div>`,
    iconSize: [26, 26],
    iconAnchor: [13, 26],
    popupAnchor: [0, -24],
  })

const ICONS = {
  start: pin('#2c3946', '🏠'),
  camp: pin('#395d73', '⛺'),
  croatia: pin('#b45309', '★'),
  actOn: pin('#0e7490', '✓'),
  actOff: pin('#94a3b8', '•'),
}

function FitBounds({ points }) {
  const map = useMap()
  useMemo(() => {
    if (points.length) {
      map.fitBounds(L.latLngBounds(points.map((p) => [p.lat, p.lng])).pad(0.2))
    }
  }, [points, map])
  return null
}

export default function MapView({ selectedCroatiaId, checkedActivities }) {
  const selected = CROATIA.find((c) => c.id === selectedCroatiaId) || CROATIA[0]

  const overnights = [
    { ...WAYPOINTS.goteborg, icon: ICONS.start, label: 'Göteborg – start & mål' },
    { ...ONWAY.lh, icon: ICONS.camp, label: `${ONWAY.lh.name} (camping)` },
    { ...ONWAY.bw, icon: ICONS.camp, label: `${ONWAY.bw.name} (camping)` },
    { ...selected, icon: ICONS.croatia, label: `${selected.name} (Kroatien-bas)` },
  ]

  const route = [
    [WAYPOINTS.goteborg.lat, WAYPOINTS.goteborg.lng],
    [ONWAY.lh.lat, ONWAY.lh.lng],
    [ONWAY.bw.lat, ONWAY.bw.lng],
    [selected.lat, selected.lng],
  ]

  const fitPoints = [...overnights]

  return (
    <section id="karta" className="scroll-mt-4">
      <h2 className="mb-3 text-lg font-bold text-fjord-900">Karta · etapper & valda platser</h2>
      <div className="overflow-hidden rounded-xl border border-fjord-100 shadow-sm">
        <MapContainer
          center={[50, 14]}
          zoom={5}
          scrollWheelZoom={false}
          style={{ height: '460px', width: '100%' }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          <Polyline positions={route} pathOptions={{ color: '#395d73', weight: 3, dashArray: '6 6' }} />

          {overnights.map((p, i) => (
            <Marker key={`o${i}`} position={[p.lat, p.lng]} icon={p.icon}>
              <Popup>{p.label}</Popup>
            </Marker>
          ))}

          {ACTIVITIES.map((a) => {
            const on = !!checkedActivities[a.id]
            return (
              <Marker key={a.id} position={[a.lat, a.lng]} icon={on ? ICONS.actOn : ICONS.actOff}>
                <Popup>
                  <strong>{a.name}</strong>
                  <br />
                  {a.town}
                  <br />
                  {on ? '✓ vald' : 'ej vald'}
                </Popup>
              </Marker>
            )
          })}

          <FitBounds points={fitPoints} />
        </MapContainer>
      </div>
      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-fjord-500">
        <span>🏠 Start/mål</span>
        <span>⛺ Camping på vägen</span>
        <span>★ Kroatien-bas</span>
        <span className="text-cyan-700">✓ Vald aktivitet</span>
        <span className="text-slate-400">• Ej vald aktivitet</span>
      </div>
    </section>
  )
}
