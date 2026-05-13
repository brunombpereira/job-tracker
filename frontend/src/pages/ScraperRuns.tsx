import { useState } from "react";
import { useEnqueueScraperRun, useScraperRuns } from "@/hooks/useScraperRuns";
import type { ScraperRun } from "@/api/scrapers";

const SOURCE_PRESETS: Record<string, { label: string; defaultParams: Record<string, string>; help: string }> = {
  adzuna: {
    label: "Adzuna",
    defaultParams: { keywords: "developer", where: "Portugal", country: "pt" },
    help: "REST API · requires ADZUNA_APP_ID + ADZUNA_APP_KEY env vars on the server",
  },
  itjobs: {
    label: "ITJobs.pt",
    defaultParams: { role: "engenharia-informatica" },
    help: "RSS feed · no API key required",
  },
};

const STATUS_BADGE: Record<ScraperRun["status"], string> = {
  pending:   "bg-slate-100  text-slate-700",
  running:   "bg-blue-100   text-blue-800",
  succeeded: "bg-emerald-100 text-emerald-800",
  failed:    "bg-rose-100   text-rose-800",
};

const fmt = (iso: string | null) =>
  iso ? new Date(iso).toLocaleString() : "—";

export const ScraperRuns = () => {
  const { data, isLoading } = useScraperRuns();
  const enqueue = useEnqueueScraperRun();
  const [paramsBy, setParamsBy] = useState<Record<string, Record<string, string>>>({});

  const sources = data?.sources ?? [];
  const runs = data?.runs ?? [];

  const getParams = (src: string) =>
    paramsBy[src] ?? SOURCE_PRESETS[src]?.defaultParams ?? {};

  const setParam = (src: string, key: string, val: string) =>
    setParamsBy((prev) => ({
      ...prev,
      [src]: { ...(prev[src] ?? SOURCE_PRESETS[src]?.defaultParams ?? {}), [key]: val },
    }));

  return (
    <div className="space-y-6">
      <header>
        <h2 className="text-lg font-semibold text-slate-900">Procura automática de ofertas</h2>
        <p className="mt-1 text-sm text-slate-600">
          Os scrapers correm automaticamente todos os dias às 06h UTC (Adzuna + ITJobs.pt).
          Podes também disparar um manualmente — duplicados são ignorados por URL.
        </p>
      </header>

      {/* Sources to trigger */}
      <section className="grid gap-3 md:grid-cols-2">
        {sources.map((src) => {
          const preset = SOURCE_PRESETS[src];
          const formParams = getParams(src);
          const inProgress = runs.some(
            (r) => r.source_name === src && (r.status === "pending" || r.status === "running"),
          );
          return (
            <div key={src} className="rounded-lg border border-slate-200 bg-white p-4">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-slate-900">{preset?.label ?? src}</h3>
                {inProgress && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-0.5 text-xs text-blue-800">
                    <span className="h-2 w-2 animate-pulse rounded-full bg-blue-500" />
                    A correr
                  </span>
                )}
              </div>
              {preset?.help && <p className="mt-1 text-xs text-slate-500">{preset.help}</p>}
              <div className="mt-3 space-y-2">
                {Object.keys(preset?.defaultParams ?? {}).map((key) => (
                  <label key={key} className="block">
                    <span className="mb-1 block text-[10px] font-semibold uppercase tracking-wide text-slate-500">
                      {key}
                    </span>
                    <input
                      value={formParams[key] ?? ""}
                      onChange={(e) => setParam(src, key, e.target.value)}
                      className="block w-full rounded border border-slate-300 px-2 py-1 text-sm"
                    />
                  </label>
                ))}
              </div>
              <button
                type="button"
                onClick={() => enqueue.mutate({ source: src, params: formParams })}
                disabled={enqueue.isPending || inProgress}
                className="mt-3 w-full rounded bg-brand-accent px-3 py-1.5 text-sm font-medium text-white transition hover:bg-brand disabled:opacity-50"
              >
                Correr agora
              </button>
            </div>
          );
        })}
      </section>

      {/* Run history */}
      <section>
        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Últimas execuções
        </h3>
        {isLoading ? (
          <p className="text-sm text-slate-400">A carregar...</p>
        ) : runs.length === 0 ? (
          <p className="rounded border border-dashed border-slate-300 bg-white px-3 py-4 text-center text-sm text-slate-500">
            Ainda não houve execuções. Dispara uma acima ou espera pelo cron diário.
          </p>
        ) : (
          <ul className="space-y-2">
            {runs.map((run) => (
              <li
                key={run.id}
                className="rounded border border-slate-200 bg-white px-3 py-2 text-sm"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${
                        STATUS_BADGE[run.status]
                      }`}
                    >
                      {run.status}
                    </span>
                    <strong className="text-slate-900">{run.source_name}</strong>
                    {run.status === "succeeded" && (
                      <span className="text-xs text-slate-500">
                        +{run.offers_created} novas · {run.offers_skipped} duplicadas ·{" "}
                        {run.offers_found} encontradas
                      </span>
                    )}
                  </div>
                  <span className="text-xs text-slate-400">{fmt(run.created_at)}</span>
                </div>
                {run.error_message && (
                  <p className="mt-1 text-xs text-rose-700">{run.error_message}</p>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
};
