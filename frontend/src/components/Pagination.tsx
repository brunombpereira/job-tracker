interface Props {
  page: number;
  perPage: number;
  total: number;
  onPageChange: (page: number) => void;
}

export const Pagination = ({ page, perPage, total, onPageChange }: Props) => {
  const totalPages = Math.max(1, Math.ceil(total / perPage));
  if (totalPages <= 1) return null;

  const canPrev = page > 1;
  const canNext = page < totalPages;

  const start = (page - 1) * perPage + 1;
  const end = Math.min(total, page * perPage);

  return (
    <nav className="mt-5 flex items-center justify-between rounded-xl border border-edge bg-surface-raised px-4 py-3 text-sm shadow-soft">
      <span className="text-ink-soft">
        <strong className="text-ink">
          {start}–{end}
        </strong>{" "}
        de <strong className="text-ink">{total}</strong>
      </span>
      <div className="flex items-center gap-2">
        <button
          type="button"
          disabled={!canPrev}
          onClick={() => onPageChange(page - 1)}
          className="rounded-lg border border-edge-strong px-3 py-1.5 text-sm font-medium text-ink-soft transition enabled:hover:bg-surface-sunken disabled:opacity-40"
        >
          ← Anterior
        </button>
        <span className="px-2 text-ink-muted">
          Página <strong className="text-ink">{page}</strong> /{" "}
          <strong className="text-ink">{totalPages}</strong>
        </span>
        <button
          type="button"
          disabled={!canNext}
          onClick={() => onPageChange(page + 1)}
          className="rounded-lg border border-edge-strong px-3 py-1.5 text-sm font-medium text-ink-soft transition enabled:hover:bg-surface-sunken disabled:opacity-40"
        >
          Seguinte →
        </button>
      </div>
    </nav>
  );
};
