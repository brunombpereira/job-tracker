import { useState } from "react";
import { useOffers } from "@/hooks/useOffers";
import { OfferCard } from "@/components/OfferCard";
import type { OfferStatus } from "@/types/offer";

const STATUSES: OfferStatus[] = ["new", "interested", "applied", "interview", "offer", "rejected"];

export const OffersList = () => {
  const [selectedStatuses, setSelectedStatuses] = useState<OfferStatus[]>([]);
  const [search, setSearch] = useState("");

  const { data, isLoading, error } = useOffers({
    status: selectedStatuses.length ? selectedStatuses : undefined,
    search: search || undefined,
  });

  const toggleStatus = (s: OfferStatus) =>
    setSelectedStatuses((prev) => (prev.includes(s) ? prev.filter((x) => x !== s) : [...prev, s]));

  return (
    <div className="container mx-auto max-w-6xl px-4 py-6">
      <h1 className="mb-4 text-2xl font-bold text-brand">JobTracker</h1>

      <div className="mb-4 flex flex-wrap gap-2">
        <input
          type="search"
          placeholder="Pesquisar empresa ou cargo..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 min-w-[200px] rounded border border-slate-300 px-3 py-1.5 text-sm focus:border-brand-accent focus:outline-none"
        />
        {STATUSES.map((s) => (
          <button
            key={s}
            type="button"
            onClick={() => toggleStatus(s)}
            className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-wide transition ${
              selectedStatuses.includes(s)
                ? "border-brand-accent bg-brand-accent text-white"
                : "border-slate-300 bg-white text-slate-600 hover:border-brand-accent"
            }`}
          >
            {s}
          </button>
        ))}
      </div>

      {isLoading && <p className="text-slate-500">A carregar...</p>}
      {error && <p className="text-rose-600">Erro a carregar ofertas.</p>}

      {data && (
        <>
          <p className="mb-3 text-sm text-slate-500">{data.total} ofertas</p>
          <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
            {data.offers.map((offer) => (
              <OfferCard key={offer.id} offer={offer} />
            ))}
          </div>
        </>
      )}
    </div>
  );
};
