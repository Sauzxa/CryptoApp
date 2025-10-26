/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      fontFamily: {
        'inter': ['Inter', 'sans-serif'],
      },
      backgroundColor: {
        'dark-primary': '#0D0D0D',
        'dark-secondary': '#111827',
        'light-primary': '#FFFFFF',
        'light-secondary': '#F7F7F7',
      },
      gradientColorStops: {
        'light-gradient-start': '#FFFFFF',
        'light-gradient-end': '#E3E3E3',
        'dark-gradient-start': '#111827',
        'dark-gradient-end': '#1F2937',
      },
      colors: {
        'primary-button': '#D32F2F',
      },
    },
  },
  plugins: [],
}
