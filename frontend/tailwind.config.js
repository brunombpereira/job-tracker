/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        // Notion-flavored palette wired to CSS variables so a single `.dark`
        // toggle on <html> swaps every utility (bg-surface, text-ink, ...).
        surface: {
          DEFAULT: "rgb(var(--surface) / <alpha-value>)",
          raised:  "rgb(var(--surface-raised) / <alpha-value>)",
          sunken:  "rgb(var(--surface-sunken) / <alpha-value>)",
        },
        ink: {
          DEFAULT: "rgb(var(--ink) / <alpha-value>)",
          soft:    "rgb(var(--ink-soft) / <alpha-value>)",
          muted:   "rgb(var(--ink-muted) / <alpha-value>)",
        },
        edge: {
          DEFAULT: "rgb(var(--edge) / <alpha-value>)",
          strong:  "rgb(var(--edge-strong) / <alpha-value>)",
        },
        accent: {
          DEFAULT: "rgb(var(--accent) / <alpha-value>)",
          soft:    "rgb(var(--accent-soft) / <alpha-value>)",
          ghost:   "rgb(var(--accent-ghost) / <alpha-value>)",
          deep:    "rgb(var(--accent-deep) / <alpha-value>)",
        },
        // Legacy brand-* aliases — kept so existing components compile while
        // we migrate them piece by piece. Map to the new accent ramp.
        brand: {
          DEFAULT: "rgb(var(--accent) / <alpha-value>)",
          dark:    "rgb(var(--accent-deep) / <alpha-value>)",
          accent:  "rgb(var(--accent) / <alpha-value>)",
          light:   "rgb(var(--accent-soft) / <alpha-value>)",
        },
      },
      fontFamily: {
        sans:  ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
        serif: ['"Source Serif 4"', "ui-serif", "Georgia", "serif"],
      },
      borderRadius: {
        xl: "14px",
        "2xl": "20px",
      },
      boxShadow: {
        soft:  "0 1px 2px 0 rgb(0 0 0 / 0.04), 0 1px 3px 0 rgb(0 0 0 / 0.06)",
        raise: "0 4px 8px -2px rgb(0 0 0 / 0.06), 0 2px 4px -2px rgb(0 0 0 / 0.04)",
        focus: "0 0 0 3px rgb(var(--accent-soft) / 0.6)",
      },
    },
  },
  plugins: [],
};
