import type { ReactNode } from "react";
import { ThemeToggle } from "./ThemeToggle";

export type Tab = "offers" | "search" | "settings";

interface Props {
  tab: Tab;
  onTabChange: (t: Tab) => void;
  /** Page-specific buttons (view toggle, new-offer, etc.). Rendered on the
   *  right, isolated from the navigation — they can appear/disappear
   *  between views without ever shifting the tabs. */
  actions?: ReactNode;
  subtitle?: string;
}

export function AppHeader({ tab, onTabChange, actions, subtitle }: Props) {
  return (
    <header className="border-b border-edge bg-surface-raised">
      <div className="flex flex-wrap items-center gap-x-6 gap-y-3 px-4 py-4">
        {/* Brand + navigation — anchored left, never moves between views. */}
        <div className="flex items-center gap-4 sm:gap-6">
          <div>
            <h1 className="font-serif text-2xl leading-tight text-ink">JobTracker</h1>
            {subtitle && (
              <p className="hidden text-xs text-ink-muted sm:block">{subtitle}</p>
            )}
          </div>
          <TabSwitch tab={tab} onChange={onTabChange} />
        </div>

        {/* Page actions + theme — isolated on the right. */}
        <div className="ml-auto flex flex-wrap items-center gap-2">
          {actions}
          <ThemeToggle />
        </div>
      </div>
    </header>
  );
}

const TABS: { key: Tab; label: string; icon: ReactNode }[] = [
  {
    key: "offers",
    label: "Ofertas",
    icon: (
      <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="2" y="7" width="20" height="14" rx="2" />
        <path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2" />
      </svg>
    ),
  },
  {
    key: "search",
    label: "Procurar",
    icon: (
      <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="11" cy="11" r="7" />
        <path d="m20 20-3-3" />
      </svg>
    ),
  },
  {
    key: "settings",
    label: "Perfil",
    icon: (
      <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="7" r="4" />
        <path d="M5.5 21a7 7 0 0 1 13 0" />
      </svg>
    ),
  },
];

function TabSwitch({ tab, onChange }: { tab: Tab; onChange: (t: Tab) => void }) {
  return (
    <nav className="inline-flex rounded-lg border border-edge bg-surface p-0.5 text-sm font-medium">
      {TABS.map(({ key, label, icon }) => (
        <button
          key={key}
          type="button"
          onClick={() => onChange(key)}
          aria-current={tab === key ? "page" : undefined}
          className={`inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 transition ${
            tab === key
              ? "bg-surface-raised text-ink shadow-soft"
              : "text-ink-muted hover:text-ink"
          }`}
        >
          {icon}
          {label}
        </button>
      ))}
    </nav>
  );
}
