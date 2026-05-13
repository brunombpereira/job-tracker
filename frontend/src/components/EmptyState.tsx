interface Props {
  title: string;
  body?: string;
  actionLabel?: string;
  onAction?: () => void;
}

export const EmptyState = ({ title, body, actionLabel, onAction }: Props) => (
  <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-slate-300 bg-white px-6 py-12 text-center">
    <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-slate-400">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <rect x="3" y="3" width="18" height="18" rx="2" />
        <path d="M9 9h6M9 13h6M9 17h4" strokeLinecap="round" />
      </svg>
    </div>
    <h3 className="font-semibold text-slate-900">{title}</h3>
    {body && <p className="mt-1 text-sm text-slate-500">{body}</p>}
    {actionLabel && onAction && (
      <button
        type="button"
        onClick={onAction}
        className="mt-4 rounded bg-brand-accent px-3 py-1.5 text-sm font-medium text-white transition hover:bg-brand"
      >
        {actionLabel}
      </button>
    )}
  </div>
);
