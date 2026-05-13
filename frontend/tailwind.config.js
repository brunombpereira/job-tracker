/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: "#1F4E79",
          dark: "#2b3a47",
          accent: "#4a90b8",
          light: "#6ab0d6",
        },
      },
    },
  },
  plugins: [],
};
