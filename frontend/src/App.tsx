import { useEffect, useState } from "react";
import { OffersList } from "@/pages/OffersList";
import { Search } from "@/pages/Search";
import { AppHeader, type Tab } from "@/components/AppHeader";

const readInitialTab = (): Tab => {
  if (typeof window === "undefined") return "offers";
  const t = new URLSearchParams(window.location.search).get("tab");
  return t === "search" ? "search" : "offers";
};

export default function App() {
  const [tab, setTab] = useState<Tab>(readInitialTab);

  // Sync tab into URL (?tab=search) so refresh keeps the view.
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
        <AppHeader
          tab={tab}
          onTabChange={setTab}
          subtitle="Procura automática de ofertas"
        />
        <main className="container mx-auto max-w-7xl px-4 py-8">
          <Search />
        </main>
      </div>
    );
  }

  return <OffersList tab={tab} onTabChange={setTab} />;
}
