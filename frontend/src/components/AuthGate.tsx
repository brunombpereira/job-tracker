import { useCallback, useEffect, useState } from "react";
import type { FormEvent, ReactNode } from "react";
import { getAuthStatus } from "@/api/auth";
import { clearToken, setToken } from "@/api/token";

type GateState = "checking" | "open" | "locked" | "error";

/**
 * Gates the whole app behind the shared-secret token. On mount it probes
 * GET /auth: if the server has no token configured (local dev), or the
 * stored token is accepted, it renders the app; otherwise it shows a
 * single-field login screen.
 */
export function AuthGate({ children }: { children: ReactNode }) {
  const [state, setState] = useState<GateState>("checking");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [loginError, setLoginError] = useState<string | null>(null);

  const check = useCallback(async () => {
    setState("checking");
    try {
      const status = await getAuthStatus();
      setState(!status.required || status.authenticated ? "open" : "locked");
    } catch {
      setState("error");
    }
  }, []);

  useEffect(() => {
    check();
  }, [check]);

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const candidate = password.trim();
    if (!candidate) return;

    setSubmitting(true);
    setLoginError(null);
    setToken(candidate);
    try {
      const status = await getAuthStatus();
      if (status.authenticated) {
        setPassword("");
        setState("open");
      } else {
        clearToken();
        setLoginError("Palavra-passe incorreta.");
      }
    } catch {
      clearToken();
      setLoginError("Não foi possível contactar o servidor.");
    } finally {
      setSubmitting(false);
    }
  };

  if (state === "open") return <>{children}</>;

  if (state === "checking") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-surface text-sm text-ink-muted">
        A carregar…
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-surface px-4">
      <div className="w-full max-w-sm rounded-2xl border border-edge bg-surface-raised p-8 shadow-soft">
        <h1 className="font-serif text-xl text-ink">JobTracker</h1>
        <p className="mt-1 text-sm text-ink-soft">
          {state === "error"
            ? "Não foi possível contactar o servidor."
            : "Esta instância é privada. Introduz a palavra-passe de acesso."}
        </p>

        {state === "error" ? (
          <button
            type="button"
            onClick={check}
            className="mt-5 w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white shadow-soft transition hover:bg-accent-deep"
          >
            Tentar de novo
          </button>
        ) : (
          <form onSubmit={onSubmit} className="mt-5 space-y-3">
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Palavra-passe"
              autoFocus
              className="block w-full rounded-lg border border-edge-strong bg-surface px-3 py-2 text-sm text-ink placeholder:text-ink-muted focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-soft"
            />
            {loginError && (
              <p className="text-xs text-rose-600 dark:text-rose-400">{loginError}</p>
            )}
            <button
              type="submit"
              disabled={submitting || !password.trim()}
              className="w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white shadow-soft transition hover:bg-accent-deep disabled:opacity-50"
            >
              {submitting ? "A verificar…" : "Entrar"}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
