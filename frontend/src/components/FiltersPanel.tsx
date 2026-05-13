import type { OfferFilters, OfferModality, OfferStatus } from "@/types/offer";
import { MODALITY_VALUES, STATUS_VALUES } from "@/types/offer";

interface Props {
  filters: OfferFilters;
  onChange: (filters: OfferFilters) => void;
}

export const FiltersPanel = ({ filters, onChange }: Props) => {
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

  const clearAll = () =>
    onChange({ sort: filters.sort, per_page: filters.per_page, search: filters.search });

  const activeCount =
    (filters.status?.length ?? 0) +
    (filters.modality ? 1 : 0) +
    (filters.match_score_gte ? 1 : 0) +
    (filters.match_score_lte ? 1 : 0) +
    (filters.location ? 1 : 0) +
    (filters.include_archived ? 1 : 0);

  return (
    <aside className="space-y-5 rounded-xl border border-edge bg-surface-raised p-5 text-sm shadow-soft">
      <header className="flex items-center justify-between">
        <h3 className="font-serif text-base text-ink">Filtros</h3>
        {activeCount > 0 && (
          <button
            type="button"
            onClick={clearAll}
            className="text-xs text-ink-muted underline-offset-2 hover:text-accent hover:underline"
          >
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
