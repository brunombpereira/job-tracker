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

  const clearAll = () =>
    onChange({ sort: filters.sort, per_page: filters.per_page, search: filters.search });

  const activeCount =
    (filters.status?.length ?? 0) +
    (filters.modality ? 1 : 0) +
    (filters.match_score_gte ? 1 : 0) +
    (filters.match_score_lte ? 1 : 0) +
    (filters.location ? 1 : 0);

  return (
    <aside className="space-y-4 rounded-lg border border-slate-200 bg-white p-4 text-sm">
      <header className="flex items-center justify-between">
        <h3 className="font-semibold text-slate-900">Filtros</h3>
        {activeCount > 0 && (
          <button
            type="button"
            onClick={clearAll}
            className="text-xs text-slate-500 underline-offset-2 hover:text-brand-accent hover:underline"
          >
            Limpar ({activeCount})
          </button>
        )}
      </header>

      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
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
                    ? "border-brand-accent bg-brand-accent text-white"
                    : "border-slate-300 bg-white text-slate-600 hover:border-brand-accent"
                }`}
              >
                {s}
              </button>
            );
          })}
        </div>
      </section>

      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Modalidade
        </h4>
        <select
          value={filters.modality ?? ""}
          onChange={(e) => setModality(e.target.value)}
          className="block w-full rounded border border-slate-300 px-2 py-1.5 text-sm"
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
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
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
            className="w-full rounded border border-slate-300 px-2 py-1.5 text-sm"
          />
          <span className="text-slate-400">–</span>
          <input
            type="number"
            min={1}
            max={5}
            placeholder="max"
            value={filters.match_score_lte ?? ""}
            onChange={(e) => setMatch("match_score_lte")(e.target.value)}
            className="w-full rounded border border-slate-300 px-2 py-1.5 text-sm"
          />
        </div>
      </section>

      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Localização
        </h4>
        <input
          type="text"
          placeholder="ex.: Porto"
          value={filters.location ?? ""}
          onChange={(e) => setLocation(e.target.value)}
          className="block w-full rounded border border-slate-300 px-2 py-1.5 text-sm"
        />
      </section>
    </aside>
  );
};
