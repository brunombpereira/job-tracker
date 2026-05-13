import type { OfferFilters, OfferModality, OfferStatus } from "@/types/offer";
import { MODALITY_VALUES, STATUS_VALUES } from "@/types/offer";
import { useSources } from "@/hooks/useSources";

interface Props {
  filters: OfferFilters;
  onChange: (filters: OfferFilters) => void;
}

export const FiltersPanel = ({ filters, onChange }: Props) => {
  const { data: sources } = useSources();
  const toggleStatus = (s: OfferStatus) => {
    const current = filters.status ?? [];
    const next = current.includes(s) ? current.filter((x) => x !== s) : [...current, s];
    onChange({ ...filters, status: next.length ? next : undefined, page: 1 });
  };

  const setModality = (m: string) => {
    onChange({
      ...filters,
      modality: (m || undefined) as OfferModality | undefined,
      page: 1,
    });
  };

  const setMatch = (key: "match_score_gte" | "match_score_lte") => (raw: string) => {
    const n = raw ? Number(raw) : undefined;
    onChange({ ...filters, [key]: n, page: 1 });
  };

  const setLocation = (loc: string) =>
    onChange({ ...filters, location: loc || undefined, page: 1 });

  const setArchived = (on: boolean) =>
    onChange({ ...filters, include_archived: on || undefined, page: 1 });

  const setSource = (id: number | undefined) =>
    onChange({ ...filters, source_id: id, page: 1 });

  const clearAll = () =>
    onChange({ sort: filters.sort, per_page: filters.per_page, search: filters.search });

  const activeCount =
    (filters.status?.length ?? 0) +
    (filters.modality ? 1 : 0) +
    (filters.source_id ? 1 : 0) +
    (filters.match_score_gte ? 1 : 0) +
    (filters.match_score_lte ? 1 : 0) +
    (filters.location ? 1 : 0) +
    (filters.include_archived ? 1 : 0);

  const sourcesWithOffers = (sources ?? []).filter((s) => s.count > 0);

  return (
    <aside className="space-y-5 rounded-xl border border-edge bg-surface-raised p-5 text-sm shadow-soft">
      <header className="flex items-center justify-between gap-2">
        <h3 className="inline-flex items-center gap-2 font-serif text-base text-ink">
          <svg viewBox="0 0 24 24" className="h-4 w-4 text-ink-muted" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" />
          </svg>
          Filtros
        </h3>
        {activeCount > 0 && (
          <button
            type="button"
            onClick={clearAll}
            className="inline-flex items-center gap-1 rounded-md border border-edge-strong bg-surface px-2 py-1 text-[10px] font-semibold uppercase tracking-wide text-ink-soft transition hover:border-accent hover:text-accent"
            aria-label={`Limpar ${activeCount} filtro(s)`}
          >
            <svg viewBox="0 0 24 24" className="h-3 w-3" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
            Limpar ({activeCount})
          </button>
        )}
      </header>

      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
          Status
        </h4>
        <div className="flex flex-wrap gap-1.5">
          {STATUS_VALUES.filter((s) => s !== "archived").map((s) => {
            const active = filters.status?.includes(s);
            return (
              <button
                key={s}
                type="button"
                onClick={() => toggleStatus(s)}
                className={`rounded-full border px-2.5 py-0.5 text-xs font-medium uppercase tracking-wide transition ${
                  active
                    ? "border-accent bg-accent text-white"
                    : "border-edge-strong bg-surface-raised text-ink-soft hover:border-accent"
                }`}
              >
                {s}
              </button>
            );
          })}
        </div>
      </section>

      {sourcesWithOffers.length > 0 && (
        <section>
          <div className="mb-2 flex items-center justify-between">
            <h4 className="text-xs font-semibold uppercase tracking-wide text-ink-muted">
              Fonte
            </h4>
            {filters.source_id != null && (
              <button
                type="button"
                onClick={() => setSource(undefined)}
                className="text-[10px] uppercase tracking-wide text-ink-muted underline-offset-2 hover:text-accent hover:underline"
              >
                Limpar
              </button>
            )}
          </div>
          <div
            className="grid gap-1.5"
            style={{
              gridTemplateColumns: `repeat(${Math.max(
                2,
                Math.ceil(sourcesWithOffers.length / 2),
              )}, minmax(0, 1fr))`,
            }}
          >
            {sourcesWithOffers.map((s) => {
              const active = filters.source_id === s.id;
              return (
                <button
                  key={s.id}
                  type="button"
                  onClick={() => setSource(active ? undefined : s.id)}
                  className={`inline-flex items-center gap-1.5 truncate rounded-lg border px-2.5 py-1.5 text-xs font-medium transition ${
                    active
                      ? "border-accent bg-accent text-white"
                      : "border-edge-strong bg-surface-raised text-ink-soft hover:border-accent"
                  }`}
                  title={`${s.name} · ${s.count} oferta(s)`}
                >
                  <span
                    aria-hidden="true"
                    className="h-1.5 w-1.5 shrink-0 rounded-full"
                    style={{ backgroundColor: active ? "currentColor" : s.color }}
                  />
                  <span className="truncate">{s.name}</span>
                  <span className={`ml-auto shrink-0 ${active ? "opacity-80" : "text-ink-muted"}`}>
                    {s.count}
                  </span>
                </button>
              );
            })}
          </div>
        </section>
      )}

      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
          Modalidade
        </h4>
        <select
          value={filters.modality ?? ""}
          onChange={(e) => setModality(e.target.value)}
          className="block w-full rounded-lg border border-edge-strong bg-surface-raised px-2.5 py-1.5 text-sm text-ink focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-soft"
        >
          <option value="">Todas</option>
          {MODALITY_VALUES.map((m) => (
            <option key={m} value={m}>
              {m}
            </option>
          ))}
        </select>
      </section>

      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
          Match score
        </h4>
        <div className="flex items-center gap-2">
          <input
            type="number"
            min={1}
            max={5}
            placeholder="min"
            value={filters.match_score_gte ?? ""}
            onChange={(e) => setMatch("match_score_gte")(e.target.value)}
            className="w-full rounded-lg border border-edge-strong bg-surface-raised px-2.5 py-1.5 text-sm text-ink focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-soft"
          />
          <span className="text-ink-muted">–</span>
          <input
            type="number"
            min={1}
            max={5}
            placeholder="max"
            value={filters.match_score_lte ?? ""}
            onChange={(e) => setMatch("match_score_lte")(e.target.value)}
            className="w-full rounded-lg border border-edge-strong bg-surface-raised px-2.5 py-1.5 text-sm text-ink focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-soft"
          />
        </div>
      </section>

      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
          Localização
        </h4>
        <input
          type="text"
          placeholder="ex.: Porto"
          value={filters.location ?? ""}
          onChange={(e) => setLocation(e.target.value)}
          className="block w-full rounded-lg border border-edge-strong bg-surface-raised px-2.5 py-1.5 text-sm text-ink focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-soft"
        />
      </section>

      <section className="border-t border-edge pt-3">
        <label className="flex cursor-pointer items-center gap-2 text-xs text-ink-soft">
          <input
            type="checkbox"
            checked={Boolean(filters.include_archived)}
            onChange={(e) => setArchived(e.target.checked)}
            className="h-3.5 w-3.5 rounded border-edge-strong text-accent focus:ring-accent"
          />
          Mostrar arquivadas
        </label>
      </section>
    </aside>
  );
};
