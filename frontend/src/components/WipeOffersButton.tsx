import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { api } from "@/api/client";
import { describeError } from "@/api/errors";

interface WipeResponse {
  deleted: number;
}

const wipeOffers = async (includeArchived: boolean): Promise<WipeResponse> => {
  const res = await api.delete<WipeResponse>("/offers/destroy_all", {
    params: includeArchived ? { include_archived: "true" } : {},
  });
  return res.data;
};

/**
 * Two-click bulk delete for the offers list. Click once → button enters
 * an "armed" state for 4 seconds and asks for confirmation; click again
 * within the window → calls DELETE /offers/destroy_all and invalidates
 * every offers-related query.
 */
export const WipeOffersButton = () => {
  const [armed, setArmed] = useState(false);
  const qc = useQueryClient();

  const mutation = useMutation({
    mutationFn: () => wipeOffers(false),
    onSuccess: ({ deleted }) => {
      qc.invalidateQueries({ queryKey: ["offers"] });
      qc.invalidateQueries({ queryKey: ["sources"] });
      qc.invalidateQueries({ queryKey: ["stats"] });
      toast.success(`Apagadas ${deleted} oferta(s)`);
      setArmed(false);
    },
    onError: (err) => {
      toast.error(`Falha a limpar: ${describeError(err)}`);
      setArmed(false);
    },
  });

  const arm = () => {
    setArmed(true);
    window.setTimeout(() => setArmed(false), 4_000);
  };

  if (armed) {
    return (
      <button
        type="button"
        onClick={() => mutation.mutate()}
        disabled={mutation.isPending}
        className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-rose-500 bg-rose-500 px-4 text-sm font-medium text-white shadow-soft transition hover:bg-rose-600 disabled:opacity-60"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 6h18M8 6v-2a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M6 6l1 14a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-14" />
        </svg>
        {mutation.isPending ? "A apagar…" : "Confirmar — apagar tudo"}
      </button>
    );
  }

  return (
    <button
      type="button"
      onClick={arm}
      className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-edge-strong bg-surface-raised px-4 text-sm font-medium text-ink-soft transition hover:border-rose-400 hover:text-rose-500"
      title="Apaga todas as ofertas activas para começares uma pesquisa limpa"
    >
      <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 6h18M8 6v-2a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M6 6l1 14a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-14" />
      </svg>
      Limpar ofertas
    </button>
  );
};
