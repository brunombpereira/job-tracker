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
    <nav className="mt-4 flex items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm">
      <span className="text-slate-600">
        <strong className="text-slate-900">
          {start}–{end}
        </strong>{" "}
        de <strong className="text-slate-900">{total}</strong>
      </span>
      <div className="flex items-center gap-2">
        <button
          type="button"
          disabled={!canPrev}
          onClick={() => onPageChange(page - 1)}
          className="rounded border border-slate-300 px-3 py-1 text-sm font-medium text-slate-700 transition enabled:hover:bg-slate-50 disabled:opacity-40"
        >
          ← Anterior
        </button>
        <span className="px-2 text-slate-500">
          Página <strong className="text-slate-900">{page}</strong> /{" "}
          <strong className="text-slate-900">{totalPages}</strong>
        </span>
        <button
          type="button"
          disabled={!canNext}
          onClick={() => onPageChange(page + 1)}
          className="rounded border border-slate-300 px-3 py-1 text-sm font-medium text-slate-700 transition enabled:hover:bg-slate-50 disabled:opacity-40"
        >
          Seguinte →
        </button>
      </div>
    </nav>
  );
};
