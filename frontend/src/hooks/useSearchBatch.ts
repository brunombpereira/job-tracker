import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  createSearchBatch,
  getSearchBatch,
  isTerminalStatus,
  listSearchBatches,
  type CreateBatchInput,
  type SearchBatch,
} from "@/api/batches";
import { describeError } from "@/api/errors";

const POLL_MS = 2_000;

/** Index: source catalog + recent batches. Refreshes on demand. */
export const useSearchBatchesIndex = () =>
  useQuery({
    queryKey: ["search_batches"],
    queryFn: listSearchBatches,
  });

/**
 * Track a single batch with auto-polling while non-terminal. When the
 * batch reaches a terminal status, the offers list is invalidated and a
 * summary toast is fired exactly once.
 */
export const useSearchBatch = (id: number | null) => {
  const qc = useQueryClient();
  const announcedRef = useRef<number | null>(null);

  const query = useQuery({
    queryKey: ["search_batch", id],
    queryFn: () => getSearchBatch(id as number),
    enabled: id != null,
    refetchInterval: (q) => {
      const data = q.state.data;
      return data && !isTerminalStatus(data.status) ? POLL_MS : false;
    },
  });

  useEffect(() => {
    const batch = query.data;
    if (!batch || !isTerminalStatus(batch.status)) return;
    if (announcedRef.current === batch.id) return;
    announcedRef.current = batch.id;

    qc.invalidateQueries({ queryKey: ["offers"] });
    qc.invalidateQueries({ queryKey: ["search_batches"] });
    qc.invalidateQueries({ queryKey: ["scraper_health"] });

    const created = batch.offers_created;
    const sources = batch.runs.length;
    const failed = batch.runs.filter((r) => r.status === "failed").length;

    if (batch.status === "succeeded") {
      toast.success(`${created} nova(s) oferta(s) de ${sources} source(s)`);
    } else if (batch.status === "partial") {
      toast.warning(
        `${created} nova(s) · ${failed} de ${sources} source(s) falharam`,
      );
    } else {
      toast.error(`Todas as ${sources} source(s) falharam`);
    }
  }, [query.data, qc]);

  return query;
};

/** Mutation: start a batch, returning its id so the caller can subscribe. */
export const useCreateBatch = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateBatchInput) => createSearchBatch(input),
    onSuccess: (batch) => {
      qc.invalidateQueries({ queryKey: ["search_batches"] });
      qc.setQueryData(["search_batch", batch.id], batch);
    },
    onError: (err) => {
      toast.error(`Não foi possível iniciar a procura: ${describeError(err)}`);
    },
  });
};

/** Convenience: own the active batch id locally + auto-poll it. */
export const useActiveBatch = () => {
  const [activeId, setActiveId] = useState<number | null>(null);
  const batchQuery = useSearchBatch(activeId);
  return { activeId, setActiveId, batch: batchQuery.data ?? null };
};

export type { SearchBatch };
