import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { api } from "@/api/client";
import { describeError } from "@/api/errors";

interface WipeResponse {
  archived: number;
  deleted: number;
}

type Mode = "soft" | "hard";

const wipeOffers = async (mode: Mode): Promise<WipeResponse> => {
  const params: Record<string, string> =
    mode === "hard" ? { hard: "true", include_archived: "true" } : {};
  const res = await api.delete<WipeResponse>("/offers/destroy_all", { params });
  return res.data;
};

/**
 * Two-step bulk wipe with two destructive modes:
 *
 *  • "Arquivar" (soft, default): every active Offer flips to archived=true.
 *    URLs stay in the DB so the next scrape ignores them — discards don't
 *    come back.
 *
 *  • "Reset total" (hard): every Offer row is destroyed regardless of
 *    archived flag. URLs are gone — the next scrape brings back every
 *    listing currently published, including ones previously discarded.
 *
 * Click once → armed for 4 s with both options visible. Pick one or wait
 * for the timeout. No accidental fires, no nested modals.
 */
export const WipeOffersButton = () => {
  const [armed, setArmed] = useState(false);
  const qc = useQueryClient();

  const mutation = useMutation({
    mutationFn: (mode: Mode) => wipeOffers(mode),
    onSuccess: ({ archived, deleted }, mode) => {
      qc.invalidateQueries({ queryKey: ["offers"] });
      qc.invalidateQueries({ queryKey: ["sources"] });
      qc.invalidateQueries({ queryKey: ["stats"] });
      if (mode === "hard") {
        toast.success(
          `Reset total · ${deleted} oferta(s) apagadas. A próxima procura traz tudo de novo.`,
        );
      } else {
        toast.success(
          `Arquivadas ${archived} oferta(s) · os URLs ficam no histórico para evitar re-importação.`,
        );
      }
      setArmed(false);
    },
    onError: (err) => {
      toast.error(`Falha: ${describeError(err)}`);
      setArmed(false);
    },
  });

  const arm = () => {
    setArmed(true);
    window.setTimeout(() => setArmed(false), 4_000);
  };

  if (armed) {
    return (
      <div className="inline-flex items-center gap-2">
        <button
          type="button"
          onClick={() => mutation.mutate("soft")}
          disabled={mutation.isPending}
          className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-amber-400 bg-amber-50 px-3 text-sm font-medium text-amber-800 shadow-soft transition hover:bg-amber-100 disabled:opacity-60 dark:bg-amber-950 dark:text-amber-200 dark:hover:bg-amber-900"
          title="Arquiva todas as ofertas activas. URLs ficam no DB — ofertas descartadas não vão voltar."
        >
          <ArchiveIcon />
          Arquivar
        </button>
        <button
          type="button"
          onClick={() => mutation.mutate("hard")}
          disabled={mutation.isPending}
          className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-rose-500 bg-rose-500 px-3 text-sm font-medium text-white shadow-soft transition hover:bg-rose-600 disabled:opacity-60"
          title="Apaga TUDO incluindo arquivadas. Próxima procura traz tudo de novo."
        >
          <SkullIcon />
          Reset total
        </button>
        <button
          type="button"
          onClick={() => setArmed(false)}
          className="inline-flex h-9 items-center rounded-lg border border-edge-strong bg-surface-raised px-3 text-xs font-medium text-ink-muted transition hover:text-ink"
        >
          Cancelar
        </button>
      </div>
    );
  }

  return (
    <button
      type="button"
      onClick={arm}
      className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-edge-strong bg-surface-raised px-4 text-sm font-medium text-ink-soft transition hover:border-rose-400 hover:text-rose-500"
      title="Arquivar todas as ofertas ou reset total — escolhes na confirmação"
    >
      <TrashIcon />
      Limpar ofertas
    </button>
  );
};

function TrashIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 6h18M8 6v-2a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M6 6l1 14a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-14" />
    </svg>
  );
}

function ArchiveIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="18" height="5" rx="1" />
      <path d="M5 8v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8M10 12h4" />
    </svg>
  );
}

function SkullIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 2a9 9 0 0 0-9 9c0 3 1.5 5.6 4 7v3h10v-3c2.5-1.4 4-4 4-7a9 9 0 0 0-9-9z" />
      <circle cx="9" cy="11" r="1.2" fill="currentColor" />
      <circle cx="15" cy="11" r="1.2" fill="currentColor" />
      <path d="M10 17h4" />
    </svg>
  );
}
