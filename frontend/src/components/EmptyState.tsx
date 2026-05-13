interface Props {
  title: string;
  body?: string;
  actionLabel?: string;
  onAction?: () => void;
}

export const EmptyState = ({ title, body, actionLabel, onAction }: Props) => (
  <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-edge-strong bg-surface-raised px-6 py-16 text-center">
    <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-accent-ghost text-accent dark:bg-accent-soft/30">
      <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
        <rect x="3" y="3" width="18" height="18" rx="3" />
        <path d="M9 9h6M9 13h6M9 17h4" strokeLinecap="round" />
      </svg>
    </div>
    <h3 className="font-serif text-lg text-ink">{title}</h3>
    {body && <p className="mt-1.5 max-w-md text-sm text-ink-soft">{body}</p>}
    {actionLabel && onAction && (
      <button
        type="button"
        onClick={onAction}
        className="mt-5 rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white shadow-soft transition hover:bg-accent-deep"
      >
        {actionLabel}
      </button>
    )}
  </div>
);
