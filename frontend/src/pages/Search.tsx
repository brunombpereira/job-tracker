import { useEffect, useMemo, useState } from "react";
import { SourceCard } from "@/components/SourceCard";
import {
  useCreateBatch,
  useSearchBatch,
  useSearchBatchesIndex,
} from "@/hooks/useSearchBatch";
import type { BatchRun, BatchStatus, SearchBatch } from "@/api/batches";

const STATUS_LABEL: Record<BatchStatus, string> = {
  pending:   "Em fila",
  running:   "A correr",
  succeeded: "Concluída",
  partial:   "Parcial",
  failed:    "Falhada",
};

const STATUS_CHIP: Record<BatchStatus, string> = {
  pending:   "bg-slate-100 text-slate-700",
  running:   "bg-blue-100 text-blue-800",
  succeeded: "bg-emerald-100 text-emerald-800",
  partial:   "bg-amber-100 text-amber-800",
  failed:    "bg-rose-100 text-rose-800",
};

const fmt = (iso: string | null) => (iso ? new Date(iso).toLocaleString() : "—");

export const Search = () => {
  const { data, isLoading } = useSearchBatchesIndex();
  const create = useCreateBatch();

  const [activeId, setActiveId] = useState<number | null>(null);
  const activeBatch = useSearchBatch(activeId);

  const sources = data?.sources ?? [];
  const recentBatches = data?.batches ?? [];

  // Restore the most-recent batch on first paint so a refresh during a run
  // keeps showing progress.
  useEffect(() => {
    if (activeId == null && recentBatches[0]) {
      setActiveId(recentBatches[0].id);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [recentBatches.length]);

  // Selection: by default every "ready" source is selected.
  const [excluded, setExcluded] = useState<Set<string>>(new Set());
  const isSelected = (key: string) => !excluded.has(key);
  const toggle = (key: string) =>
    setExcluded((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });

  const readyKeys = useMemo(
    () => sources.filter((s) => s.ready).map((s) => s.key),
    [sources],
  );
  const selectedKeys = useMemo(
    () => readyKeys.filter((k) => !excluded.has(k)),
    [readyKeys, excluded],
  );

  const liveBatch: SearchBatch | null = activeBatch.data ?? null;
  const runByKey: Record<string, BatchRun | undefined> = useMemo(() => {
    const map: Record<string, BatchRun | undefined> = {};
    for (const r of liveBatch?.runs ?? []) map[r.source_name] = r;
    return map;
  }, [liveBatch]);

  const isLive = liveBatch && (liveBatch.status === "pending" || liveBatch.status === "running");

  const onSearch = async () => {
    const batch = await create.mutateAsync({ sources: selectedKeys });
    setActiveId(batch.id);
  };

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">
            Procura automática de ofertas
          </h2>
          <p className="mt-1 text-sm text-slate-600">
            Carrega <span className="font-medium">Procurar</span> para correr todas as
            fontes em paralelo. Os scrapers também correm sozinhos diariamente às 06h UTC.
            Duplicados são ignorados por URL.
          </p>
        </div>
        <button
          type="button"
          onClick={onSearch}
          disabled={create.isPending || !!isLive || selectedKeys.length === 0}
          className="inline-flex items-center gap-2 rounded-md bg-brand px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-accent disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isLive ? (
            <>
              <span className="h-2 w-2 animate-pulse rounded-full bg-white/80" />
              A procurar em {liveBatch?.runs.length ?? 0}/{liveBatch?.sources_requested.length ?? 0}…
            </>
          ) : (
            <>
              <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2">
                <circle cx="11" cy="11" r="7" />
                <path d="m20 20-3-3" />
              </svg>
              Procurar em {selectedKeys.length} fonte(s)
            </>
          )}
        </button>
      </header>

      {/* Source grid */}
      <section>
        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Fontes
        </h3>
        {isLoading ? (
          <p className="text-sm text-slate-400">A carregar…</p>
        ) : (
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {sources.map((s) => (
              <SourceCard
                key={s.key}
                source={s}
                run={runByKey[s.key]}
                selected={isSelected(s.key)}
                onToggle={() => toggle(s.key)}
                disabled={!!isLive}
              />
            ))}
          </div>
        )}
      </section>

      {/* Current batch summary */}
      {liveBatch && (
        <section className="rounded-lg border border-slate-200 bg-white px-4 py-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Procura #{liveBatch.id}
              </span>
              <span
                className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${STATUS_CHIP[liveBatch.status]}`}
              >
                {STATUS_LABEL[liveBatch.status]}
              </span>
            </div>
            <span className="text-xs text-slate-400">
              {fmt(liveBatch.started_at)} → {fmt(liveBatch.finished_at)}
            </span>
          </div>
          {liveBatch.finished_at && (
            <p className="mt-2 text-sm text-slate-600">
              <strong>+{liveBatch.offers_created}</strong> novas ·{" "}
              {liveBatch.offers_skipped} duplicadas · {liveBatch.offers_found} encontradas
            </p>
          )}
        </section>
      )}

      {/* History */}
      <section>
        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Histórico
        </h3>
        {recentBatches.length === 0 ? (
          <p className="rounded border border-dashed border-slate-300 bg-white px-3 py-4 text-center text-sm text-slate-500">
            Sem procuras anteriores. Dispara uma acima.
          </p>
        ) : (
          <ul className="space-y-2">
            {recentBatches.map((b) => (
              <li
                key={b.id}
                className="rounded border border-slate-200 bg-white px-3 py-2 text-sm"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${STATUS_CHIP[b.status]}`}
                    >
                      {STATUS_LABEL[b.status]}
                    </span>
                    <strong className="text-slate-900">#{b.id}</strong>
                    <span className="text-xs text-slate-500">
                      {b.sources_requested.length} fonte(s) · +{b.offers_created} novas
                    </span>
                  </div>
                  <span className="text-xs text-slate-400">{fmt(b.created_at)}</span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
};
