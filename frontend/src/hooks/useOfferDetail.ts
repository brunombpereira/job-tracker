import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { createNote, deleteNote, fetchOfferDescription, getOffer } from "@/api/offers";
import { describeError } from "@/api/errors";
import type { OfferDetail } from "@/types/offer";

export const useOfferDetail = (id: number | undefined) =>
  useQuery({
    queryKey: ["offer", id],
    queryFn: () => getOffer(id as number),
    enabled: typeof id === "number",
  });

/**
 * On-demand description backfill. HTML-scraped offers (LinkedIn,
 * Net-Empregos, Teamlyzer) arrive without a description; this fetches it
 * from the offer's own page and merges it into the cached detail.
 * Silent — a failed fetch just leaves the offer description-less.
 */
export const useFetchDescription = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => fetchOfferDescription(id),
    onSuccess: (offer) => {
      qc.setQueryData<OfferDetail>(["offer", offer.id], (old) =>
        old ? { ...old, description: offer.description } : old,
      );
    },
  });
};

export const useCreateNote = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ offerId, content }: { offerId: number; content: string }) =>
      createNote(offerId, content),
    onSuccess: (_note, { offerId }) => {
      qc.invalidateQueries({ queryKey: ["offer", offerId] });
      toast.success("Nota adicionada");
    },
    onError: (err) => {
      toast.error(`Não foi possível adicionar a nota: ${describeError(err)}`);
    },
  });
};

export const useDeleteNote = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ offerId, noteId }: { offerId: number; noteId: number }) =>
      deleteNote(offerId, noteId),
    onSuccess: (_v, { offerId }) => {
      qc.invalidateQueries({ queryKey: ["offer", offerId] });
      toast.success("Nota removida");
    },
    onError: (err) => {
      toast.error(`Não foi possível remover a nota: ${describeError(err)}`);
    },
  });
};
