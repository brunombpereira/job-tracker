import { useEffect, useState } from "react";
import { OffersList } from "@/pages/OffersList";
import { Search } from "@/pages/Search";
import { ThemeToggle } from "@/components/ThemeToggle";

type Tab = "offers" | "search";

const readInitialTab = (): Tab => {
  if (typeof window === "undefined") return "offers";
  const t = new URLSearchParams(window.location.search).get("tab");
  return t === "search" ? "search" : "offers";
};

export default function App() {
  const [tab, setTab] = useState<Tab>(readInitialTab);

  // Sync tab into URL (?tab=search) so refresh keeps the view
  useEffect(() => {
    const url = new URL(window.location.href);
    if (tab === "offers") {
      url.searchParams.delete("tab");
    } else {
      url.searchParams.set("tab", tab);
    }
    window.history.replaceState({}, "", url.toString());
  }, [tab]);

  if (tab === "search") {
    return (
      <div className="min-h-screen bg-surface">
        <header className="border-b border-edge bg-surface-raised">
          <div className="container mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-4">
            <div>
              <h1 className="font-serif text-2xl text-ink">JobTracker</h1>
              <p className="hidden text-xs text-ink-muted sm:block">
                Procura automática de ofertas
              </p>
            </div>
            <div className="flex items-center gap-2">
              <TabSwitch tab={tab} onChange={setTab} />
              <ThemeToggle />
            </div>
          </div>
        </header>
        <main className="container mx-auto max-w-7xl px-4 py-6">
          <Search />
        </main>
      </div>
    );
  }

  return (
    <>
      <OffersList />
      {/* Floating tab switch on Offers page lives inside the OffersList header already
          — but we expose an alt entry point in the URL state so deep-linking works.
          To minimise edits to OffersList, we keep the switch in App's top-level
          render path only for the "search" tab. On "offers", use this floating fallback: */}
      <div className="fixed bottom-4 right-4 z-30 sm:hidden">
        <button
          type="button"
          onClick={() => setTab("search")}
          className="rounded-full bg-accent px-4 py-2.5 text-sm font-medium text-white shadow-raise transition hover:bg-accent-deep"
        >
          🔎 Procurar
        </button>
      </div>
      <div className="fixed bottom-6 right-6 z-30 hidden sm:block">
        <button
          type="button"
          onClick={() => setTab("search")}
          className="rounded-full border border-edge bg-surface-raised px-5 py-2.5 text-sm font-medium text-ink shadow-raise transition hover:border-accent hover:text-accent"
        >
          🔎 Procurar ofertas
        </button>
      </div>
    </>
  );
}

function TabSwitch({ tab, onChange }: { tab: Tab; onChange: (t: Tab) => void }) {
  return (
    <div className="inline-flex rounded border border-edge-strong bg-surface p-0.5 text-xs font-medium">
      <button
        type="button"
        onClick={() => onChange("offers")}
        className={`rounded px-3 py-1 transition ${
          tab === "offers"
            ? "bg-surface-raised text-ink shadow-sm"
            : "text-ink-muted hover:text-ink"
        }`}
      >
        Ofertas
      </button>
      <button
        type="button"
        onClick={() => onChange("search")}
        className={`rounded px-3 py-1 transition ${
          tab === "search"
            ? "bg-surface-raised text-ink shadow-sm"
            : "text-ink-muted hover:text-ink"
        }`}
      >
        Procurar
      </button>
    </div>
  );
}
