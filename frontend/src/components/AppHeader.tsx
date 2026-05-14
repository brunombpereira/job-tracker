import type { ReactNode } from "react";
import { ThemeToggle } from "./ThemeToggle";

export type Tab = "offers" | "search" | "settings";

interface Props {
  tab: Tab;
  onTabChange: (t: Tab) => void;
  /** Page-specific buttons (view toggle, new-offer, etc.) rendered between
   *  the tab switch and the theme toggle. Keeps OffersList vs Search free
   *  to add their own actions without each re-implementing the chrome. */
  actions?: ReactNode;
  subtitle?: string;
}

export function AppHeader({ tab, onTabChange, actions, subtitle }: Props) {
  return (
    <header className="border-b border-edge bg-surface-raised">
      <div className="flex flex-wrap items-center justify-between gap-3 px-4 py-4">
        <div>
          <h1 className="font-serif text-2xl text-ink">JobTracker</h1>
          {subtitle && (
            <p className="hidden text-xs text-ink-muted sm:block">{subtitle}</p>
          )}
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <TabSwitch tab={tab} onChange={onTabChange} />
          {actions}
          <ThemeToggle />
        </div>
      </div>
    </header>
  );
}

function TabSwitch({ tab, onChange }: { tab: Tab; onChange: (t: Tab) => void }) {
  return (
    <div className="inline-flex rounded-lg border border-edge bg-surface p-0.5 text-xs font-medium">
      <button
        type="button"
        onClick={() => onChange("offers")}
        className={`rounded-md px-3 py-1.5 transition ${
          tab === "offers"
            ? "bg-surface-raised text-ink shadow-soft"
            : "text-ink-muted hover:text-ink"
        }`}
      >
        Ofertas
      </button>
      <button
        type="button"
        onClick={() => onChange("search")}
        className={`inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 transition ${
          tab === "search"
            ? "bg-surface-raised text-ink shadow-soft"
            : "text-ink-muted hover:text-ink"
        }`}
      >
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current" strokeWidth="2">
          <circle cx="11" cy="11" r="7" />
          <path d="m20 20-3-3" />
        </svg>
        Procurar
      </button>
      <button
        type="button"
        onClick={() => onChange("settings")}
        className={`inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 transition ${
          tab === "settings"
            ? "bg-surface-raised text-ink shadow-soft"
            : "text-ink-muted hover:text-ink"
        }`}
      >
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
        </svg>
        Perfil
      </button>
    </div>
  );
}
