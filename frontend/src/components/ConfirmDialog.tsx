import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from "react";

/**
 * Promise-based replacement for the native `window.confirm()`.
 *
 *   const confirm = useConfirm();
 *   const ok = await confirm({
 *     title: "Arquivar oferta",
 *     message: `Apagar "${offer.title}"?`,
 *     tone: "danger",
 *   });
 *   if (ok) archive.mutate(...);
 *
 * Mounts a single dialogue at the app root; only one confirmation
 * runs at a time. Enter confirms, Esc cancels, click-outside cancels.
 * Enter/exit animations are scripted on a small state machine so the
 * unmount waits for the fade-out instead of disappearing instantly.
 */

type Tone = "danger" | "primary";

export interface ConfirmOptions {
  title: string;
  message?: ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  tone?: Tone;
}

type ConfirmFn = (opts: ConfirmOptions) => Promise<boolean>;

const ConfirmContext = createContext<ConfirmFn | null>(null);

interface InternalState extends ConfirmOptions {
  resolve: (ok: boolean) => void;
}

const EXIT_MS = 180;

export function ConfirmProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<InternalState | null>(null);
  const [exiting, setExiting] = useState(false);
  const stateRef = useRef<InternalState | null>(null);
  stateRef.current = state;

  const confirm = useCallback<ConfirmFn>((opts) => {
    return new Promise<boolean>((resolve) => {
      setExiting(false);
      setState({
        confirmLabel: "Confirmar",
        cancelLabel: "Cancelar",
        tone: "primary",
        ...opts,
        resolve,
      });
    });
  }, []);

  const handleClose = (ok: boolean) => {
    if (!stateRef.current) return;
    const { resolve } = stateRef.current;
    setExiting(true);
    window.setTimeout(() => {
      resolve(ok);
      setState(null);
      setExiting(false);
    }, EXIT_MS);
  };

  return (
    <ConfirmContext.Provider value={confirm}>
      {children}
      {state && <Dialog state={state} exiting={exiting} onClose={handleClose} />}
    </ConfirmContext.Provider>
  );
}

export function useConfirm(): ConfirmFn {
  const fn = useContext(ConfirmContext);
  if (!fn) throw new Error("useConfirm must be used inside <ConfirmProvider>");
  return fn;
}

function Dialog({
  state,
  exiting,
  onClose,
}: {
  state: InternalState;
  exiting: boolean;
  onClose: (ok: boolean) => void;
}) {
  const tone = state.tone ?? "primary";

  // Keyboard shortcuts: Enter confirms, Esc cancels. Attached at the
  // document level so the dialog doesn't need to hold focus to catch
  // them — but we also restore focus to whatever was focused before
  // the dialog opened on close.
  const previousFocusRef = useRef<HTMLElement | null>(null);
  useEffect(() => {
    previousFocusRef.current = document.activeElement as HTMLElement | null;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") { e.preventDefault(); onClose(false); }
      if (e.key === "Enter")  { e.preventDefault(); onClose(true); }
    };
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
      previousFocusRef.current?.focus?.();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const confirmClasses =
    tone === "danger"
      ? "bg-rose-500 hover:bg-rose-600 focus-visible:ring-rose-300 shadow-lg shadow-rose-500/30"
      : "bg-accent hover:bg-accent-deep focus-visible:ring-accent-soft shadow-lg shadow-accent/25";

  return (
    <div
      role="presentation"
      className={`fixed inset-0 z-[60] flex min-h-full items-center justify-center overflow-y-auto p-4 ${
        exiting ? "confirm-backdrop-exit" : "confirm-backdrop-enter"
      } bg-ink/50 backdrop-blur-md`}
      onClick={() => onClose(false)}
    >
      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="confirm-title"
        aria-describedby="confirm-body"
        onClick={(e) => e.stopPropagation()}
        className={`relative w-full max-w-md overflow-hidden rounded-3xl border border-edge bg-surface-raised shadow-2xl shadow-ink/30 ${
          exiting ? "confirm-dialog-exit" : "confirm-dialog-enter"
        }`}
      >
        {/* Decorative gradient halo so the dialog reads as a focal
            point even before the icon is parsed. */}
        <div
          aria-hidden="true"
          className={`pointer-events-none absolute -inset-px rounded-3xl opacity-70 ${
            tone === "danger"
              ? "bg-gradient-to-br from-rose-500/[0.08] via-transparent to-rose-500/[0.04]"
              : "bg-gradient-to-br from-accent/[0.08] via-transparent to-accent/[0.04]"
          }`}
        />

        <div className="relative px-8 pt-8 pb-7">
          <div className="flex items-start gap-5">
            <IconBadge tone={tone} />
            <div className="min-w-0 flex-1 pt-0.5">
              <h2 id="confirm-title" className="font-serif text-xl text-ink">
                {state.title}
              </h2>
              {state.message && (
                <div id="confirm-body" className="mt-3 text-sm leading-relaxed text-ink-soft">
                  {state.message}
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="relative flex items-center justify-end gap-3 border-t border-edge bg-surface-sunken/40 px-8 py-5">
          <button
            type="button"
            onClick={() => onClose(false)}
            className="inline-flex h-10 items-center rounded-xl border border-edge-strong bg-surface-raised px-5 text-sm font-medium text-ink-soft transition hover:border-edge hover:bg-surface-sunken focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-edge-strong"
          >
            {state.cancelLabel}
          </button>
          <button
            type="button"
            onClick={() => onClose(true)}
            autoFocus
            className={`inline-flex h-10 items-center rounded-xl px-5 text-sm font-semibold text-white transition focus-visible:outline-none focus-visible:ring-2 ${confirmClasses}`}
          >
            {state.confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

function IconBadge({ tone }: { tone: Tone }) {
  const danger = tone === "danger";
  return (
    <span
      aria-hidden="true"
      className={`relative flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl ${
        danger
          ? "bg-gradient-to-br from-rose-500/15 to-rose-500/5 text-rose-500 ring-1 ring-inset ring-rose-500/30 dark:from-rose-500/20 dark:to-rose-500/5 dark:text-rose-300"
          : "bg-gradient-to-br from-accent/20 to-accent/5 text-accent ring-1 ring-inset ring-accent/30 dark:text-accent"
      }`}
    >
      {/* Animated soft pulse behind the glyph */}
      <span
        aria-hidden="true"
        className={`absolute inset-1 rounded-xl opacity-60 blur-md ${
          danger ? "bg-rose-500/30" : "bg-accent/30"
        }`}
      />
      <span className="relative">
        {danger ? <DangerGlyph /> : <PrimaryGlyph />}
      </span>
    </span>
  );
}

function DangerGlyph() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 9v4M12 17h.01" />
      <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
    </svg>
  );
}

function PrimaryGlyph() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" />
      <path d="M9.1 9a3 3 0 1 1 5.4 1.8c-.7.6-1.5 1-1.5 2.2M12 17h.01" />
    </svg>
  );
}
