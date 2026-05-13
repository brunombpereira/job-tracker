import type { BatchRun, RunStatus, SourceMeta } from "@/api/batches";

const STATUS_CHIP: Record<RunStatus, string> = {
  pending:   "bg-slate-100 text-slate-700",
  running:   "bg-blue-100 text-blue-800",
  succeeded: "bg-emerald-100 text-emerald-800",
  failed:    "bg-rose-100 text-rose-800",
};

const STATUS_LABEL: Record<RunStatus, string> = {
  pending:   "Em fila",
  running:   "A correr",
  succeeded: "OK",
  failed:    "Falhou",
};

interface Props {
  source: SourceMeta;
  run?: BatchRun;
  selected: boolean;
  onToggle: () => void;
  disabled: boolean;
}

export const SourceCard = ({ source, run, selected, onToggle, disabled }: Props) => {
  const status = run?.status;
  const isRunning = status === "running" || status === "pending";

  return (
    <button
      type="button"
      onClick={onToggle}
      disabled={disabled || !source.ready}
      className={`group relative flex w-full flex-col gap-2 rounded-lg border p-3 text-left transition ${
        selected && source.ready
          ? "border-brand-accent bg-brand-accent/5 shadow-sm"
          : "border-slate-200 bg-white hover:border-slate-300"
      } ${!source.ready ? "cursor-not-allowed opacity-60" : "cursor-pointer"} ${
        disabled && source.ready ? "cursor-not-allowed" : ""
      }`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2">
          <span
            className="inline-block h-2.5 w-2.5 rounded-full"
            style={{ backgroundColor: source.color }}
            aria-hidden="true"
          />
          <span className="font-medium text-slate-900">{source.display_name}</span>
        </div>
        <span className="rounded-full bg-slate-100 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-slate-600">
          {source.tag}
        </span>
      </div>

      {!source.ready && (
        <p className="text-xs text-rose-700">
          Faltam env vars: {source.requires_env.join(", ")}
        </p>
      )}

      {run ? (
        <div className="mt-1 flex flex-wrap items-center justify-between gap-2 text-xs">
          <span
            className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 font-semibold uppercase tracking-wide ${
              status ? STATUS_CHIP[status] : ""
            }`}
          >
            {isRunning && (
              <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-current opacity-70" />
            )}
            {status ? STATUS_LABEL[status] : ""}
          </span>
          {run.status === "succeeded" && (
            <span className="text-slate-500">
              +{run.offers_created} novas · {run.offers_skipped} dup ·{" "}
              {run.offers_found} totais
            </span>
          )}
          {run.status === "failed" && run.error_message && (
            <span
              className="max-w-[180px] truncate text-rose-700"
              title={run.error_message}
            >
              {run.error_message}
            </span>
          )}
        </div>
      ) : (
        source.ready && (
          <p className="text-[11px] text-slate-400">
            {selected ? "Vai correr" : "Toca para incluir / excluir"}
          </p>
        )
      )}
    </button>
  );
};
