import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Relativa sökvägar så att en byggd version kan öppnas från valfri katalog.
export default defineConfig({
  base: './',
  plugins: [react()],
})
