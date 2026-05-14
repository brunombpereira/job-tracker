import { useEffect, useState } from "react";
import { OffersList } from "@/pages/OffersList";
import { Search } from "@/pages/Search";
import { Settings } from "@/pages/Settings";
import { AppHeader, type Tab } from "@/components/AppHeader";

const readInitialTab = (): Tab => {
  if (typeof window === "undefined") return "offers";
  const t = new URLSearchParams(window.location.search).get("tab");
  if (t === "search" || t === "settings") return t;
  return "offers";
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
        <main className="px-4 py-8">
          <Search />
        </main>
      </div>
    );
  }

  if (tab === "settings") {
    return (
      <div className="min-h-screen bg-surface">
        <AppHeader
          tab={tab}
          onTabChange={setTab}
          subtitle="Perfil e definições"
        />
        <main className="mx-auto max-w-3xl px-4 py-8">
          <Settings />
        </main>
      </div>
    );
  }

  return <OffersList tab={tab} onTabChange={setTab} />;
}
