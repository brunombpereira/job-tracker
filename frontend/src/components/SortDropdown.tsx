import { useEffect, useRef, useState } from "react";

export interface SortOption {
  value: string;
  label: string;
}

interface Props {
  value: string;
  options: SortOption[];
  onChange: (v: string) => void;
}

/**
 * Drop-in replacement for the native <select> styled to match the rest of
 * the app's pill buttons. Keyboard-accessible (Enter/Space to open,
 * arrows to navigate, Esc to close) and closes on outside-click.
 */
export function SortDropdown({ value, options, onChange }: Props) {
  const [open, setOpen] = useState(false);
  const [highlight, setHighlight] = useState(0);
  const rootRef = useRef<HTMLDivElement>(null);

  const current = options.find((o) => o.value === value) ?? options[0];

  // Sync highlight with current value when opening
  useEffect(() => {
    if (open) {
      const idx = options.findIndex((o) => o.value === value);
      setHighlight(idx >= 0 ? idx : 0);
    }
  }, [open, value, options]);

  // Close on outside click
  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    return () => document.removeEventListener("mousedown", onDown);
  }, [open]);

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === "Escape") {
      setOpen(false);
    } else if (e.key === "ArrowDown" && open) {
      e.preventDefault();
      setHighlight((h) => Math.min(h + 1, options.length - 1));
    } else if (e.key === "ArrowUp" && open) {
      e.preventDefault();
      setHighlight((h) => Math.max(h - 1, 0));
    } else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      if (!open) {
        setOpen(true);
      } else {
        onChange(options[highlight].value);
        setOpen(false);
      }
    }
  };

  return (
    <div ref={rootRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        onKeyDown={onKey}
        aria-haspopup="listbox"
        aria-expanded={open}
        className="inline-flex h-9 items-center gap-2 rounded-lg border border-edge-strong bg-surface-raised px-3 text-sm font-medium text-ink-soft shadow-soft transition hover:border-accent hover:text-ink focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-soft"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 6h18M6 12h12M10 18h4" />
        </svg>
        <span className="truncate">{current.label}</span>
        <svg viewBox="0 0 24 24" className={`h-3.5 w-3.5 transition ${open ? "rotate-180" : ""}`} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="m6 9 6 6 6-6" />
        </svg>
      </button>

      {open && (
        <ul
          role="listbox"
          className="absolute right-0 top-full z-30 mt-1 min-w-[14rem] overflow-hidden rounded-lg border border-edge bg-surface-raised py-1 shadow-raise"
        >
          {options.map((opt, i) => {
            const selected = opt.value === value;
            const highlighted = i === highlight;
            return (
              <li
                key={opt.value}
                role="option"
                aria-selected={selected}
                onMouseEnter={() => setHighlight(i)}
                onClick={() => {
                  onChange(opt.value);
                  setOpen(false);
                }}
                className={`flex cursor-pointer items-center justify-between gap-2 px-3 py-2 text-sm transition ${
                  highlighted ? "bg-surface-sunken text-ink" : "text-ink-soft"
                } ${selected ? "font-medium text-accent" : ""}`}
              >
                <span>{opt.label}</span>
                {selected && (
                  <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M5 13l4 4L19 7" />
                  </svg>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
