import { useState } from 'react'

// Bild med stilren platshållare om filen saknas (t.ex. boenden där sajten
// inte gick att nå för skärmdump).
export default function SmartImage({ src, alt, label, className = '' }) {
  const [failed, setFailed] = useState(!src)

  if (failed) {
    return (
      <div
        className={`flex items-center justify-center bg-gradient-to-br from-fjord-300 to-fjord-600 text-center ${className}`}
      >
        <div className="px-3">
          <div className="text-2xl">🏕️</div>
          <div className="mt-1 text-xs font-medium text-white/90">{label || 'Ingen bild'}</div>
          <div className="text-[10px] text-white/70">skärmdump saknas</div>
        </div>
      </div>
    )
  }

  return (
    <img
      src={src}
      alt={alt}
      loading="lazy"
      onError={() => setFailed(true)}
      className={className}
    />
  )
}
