/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      colors: {
        // Avskalad skandinavisk palett
        stone: {
          50: '#fafaf9',
        },
        fjord: {
          50: '#f0f5f7',
          100: '#dbe7ec',
          200: '#bcd1da',
          300: '#90b3c2',
          400: '#5d8da3',
          500: '#427188',
          600: '#395d73',
          700: '#334d5e',
          800: '#304151',
          900: '#2c3946',
        },
      },
    },
  },
  plugins: [],
}
