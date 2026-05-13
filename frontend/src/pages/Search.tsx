import { useEffect, useMemo, useState } from "react";
import { SourceCard } from "@/components/SourceCard";
import { UrlImportPanel } from "@/components/UrlImportPanel";
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
  pending:   "bg-surface-sunken text-ink-soft",
  running:   "bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-200",
  succeeded: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200",
  partial:   "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-200",
  failed:    "bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-200",
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
          <h2 className="font-serif text-2xl text-ink">
            Procura automática de ofertas
          </h2>
          <p className="mt-1 text-sm text-ink-soft">
            Carrega <span className="font-medium">Procurar</span> para correr todas as
            fontes em paralelo. Os scrapers também correm sozinhos diariamente às 06h UTC.
            Duplicados são ignorados por URL.
          </p>
        </div>
        <button
          type="button"
          onClick={onSearch}
          disabled={create.isPending || !!isLive || selectedKeys.length === 0}
          className="inline-flex items-center gap-2 rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-white shadow-soft transition hover:bg-accent-deep disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isLive ? (
            <>
              <span className="h-2 w-2 animate-pulse rounded-full bg-surface-raised/80" />
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
        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
          Fontes
        </h3>
        {isLoading ? (
          <p className="text-sm text-ink-muted">A carregar…</p>
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
        <section className="rounded-lg border border-edge bg-surface-raised px-4 py-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold uppercase tracking-wide text-ink-muted">
                Procura #{liveBatch.id}
              </span>
              <span
                className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${STATUS_CHIP[liveBatch.status]}`}
              >
                {STATUS_LABEL[liveBatch.status]}
              </span>
            </div>
            <span className="text-xs text-ink-muted">
              {fmt(liveBatch.started_at)} → {fmt(liveBatch.finished_at)}
            </span>
          </div>
          {liveBatch.finished_at && (
            <p className="mt-2 text-sm text-ink-soft">
              <strong>+{liveBatch.offers_created}</strong> novas ·{" "}
              {liveBatch.offers_skipped} duplicadas · {liveBatch.offers_found} encontradas
            </p>
          )}
        </section>
      )}

      {/* Manual URL import (LinkedIn / Indeed / Glassdoor / any JobPosting page) */}
      <UrlImportPanel />

      {/* History */}
      <section>
        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
          Histórico
        </h3>
        {recentBatches.length === 0 ? (
          <p className="rounded border border-dashed border-edge-strong bg-surface-raised px-3 py-4 text-center text-sm text-ink-muted">
            Sem procuras anteriores. Dispara uma acima.
          </p>
        ) : (
          <ul className="space-y-2">
            {recentBatches.map((b) => (
              <li
                key={b.id}
                className="rounded border border-edge bg-surface-raised px-3 py-2 text-sm"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${STATUS_CHIP[b.status]}`}
                    >
                      {STATUS_LABEL[b.status]}
                    </span>
                    <strong className="text-ink">#{b.id}</strong>
                    <span className="text-xs text-ink-muted">
                      {b.sources_requested.length} fonte(s) · +{b.offers_created} novas
                    </span>
                  </div>
                  <span className="text-xs text-ink-muted">{fmt(b.created_at)}</span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
};
