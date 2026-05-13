import { createContext, useCallback, useContext, useRef, useState, type ReactNode } from "react";

/**
 * Promise-based replacement for the native `window.confirm()` so the
 * dialogue matches the rest of the app's styling. Use the hook:
 *
 *   const confirm = useConfirm();
 *   const ok = await confirm({
 *     title: "Arquivar oferta",
 *     message: `Tens a certeza que queres arquivar "${offer.title}"?`,
 *     confirmLabel: "Arquivar",
 *     tone: "danger",
 *   });
 *   if (ok) archive.mutate(...);
 *
 * The provider mounts a single dialogue at the app root and only one
 * confirmation runs at a time — async calls await each other.
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

export function ConfirmProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<InternalState | null>(null);

  // Latest options stored on a ref so the click handlers always see the
  // current resolver without re-binding.
  const stateRef = useRef<InternalState | null>(null);
  stateRef.current = state;

  const confirm = useCallback<ConfirmFn>((opts) => {
    return new Promise<boolean>((resolve) => {
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
    stateRef.current.resolve(ok);
    setState(null);
  };

  return (
    <ConfirmContext.Provider value={confirm}>
      {children}
      {state && <Dialog state={state} onClose={handleClose} />}
    </ConfirmContext.Provider>
  );
}

export function useConfirm(): ConfirmFn {
  const fn = useContext(ConfirmContext);
  if (!fn) throw new Error("useConfirm must be used inside <ConfirmProvider>");
  return fn;
}

function Dialog({ state, onClose }: { state: InternalState; onClose: (ok: boolean) => void }) {
  const tone = state.tone ?? "primary";
  const confirmClasses =
    tone === "danger"
      ? "bg-rose-500 hover:bg-rose-600 shadow-rose-500/20"
      : "bg-accent hover:bg-accent-deep shadow-accent/20";

  // Esc closes (as cancel), Enter confirms — same shortcuts as native confirm().
  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === "Escape") onClose(false);
    if (e.key === "Enter")  onClose(true);
  };

  return (
    <div
      className="fixed inset-0 z-[60] flex items-start justify-center overflow-y-auto bg-ink/40 p-4 pt-24 backdrop-blur-sm"
      onClick={() => onClose(false)}
      onKeyDown={onKey}
      role="presentation"
    >
      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="confirm-title"
        className="w-full max-w-md rounded-2xl border border-edge bg-surface-raised shadow-raise"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-6 py-5">
          <div className="flex items-start gap-3">
            <span
              aria-hidden="true"
              className={`mt-0.5 inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full ${
                tone === "danger"
                  ? "bg-rose-100 text-rose-600 dark:bg-rose-950 dark:text-rose-300"
                  : "bg-accent-ghost text-accent dark:bg-accent-soft/30"
              }`}
            >
              {tone === "danger" ? <DangerIcon /> : <QuestionIcon />}
            </span>
            <div className="min-w-0 flex-1">
              <h2 id="confirm-title" className="font-serif text-lg text-ink">
                {state.title}
              </h2>
              {state.message && (
                <div className="mt-1.5 text-sm text-ink-soft">{state.message}</div>
              )}
            </div>
          </div>
        </div>

        <div className="flex items-center justify-end gap-2 border-t border-edge bg-surface-sunken/40 px-6 py-3">
          <button
            type="button"
            onClick={() => onClose(false)}
            className="inline-flex h-9 items-center rounded-lg border border-edge-strong bg-surface-raised px-4 text-sm font-medium text-ink-soft transition hover:bg-surface-sunken"
          >
            {state.cancelLabel}
          </button>
          <button
            type="button"
            onClick={() => onClose(true)}
            autoFocus
            className={`inline-flex h-9 items-center rounded-lg px-4 text-sm font-medium text-white shadow-soft transition ${confirmClasses}`}
          >
            {state.confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

function DangerIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 6h18M8 6v-2a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M6 6l1 14a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-14" />
    </svg>
  );
}

function QuestionIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" />
      <path d="M9.1 9a3 3 0 1 1 5.4 1.8c-.7.6-1.5 1-1.5 2.2M12 17h.01" />
    </svg>
  );
}
