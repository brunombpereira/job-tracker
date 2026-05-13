import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  listOffers,
  changeStatus,
  createOffer,
  updateOffer,
  archiveOffer,
} from "@/api/offers";
import { describeError } from "@/api/errors";
import type { Offer, OfferFilters, OfferStatus } from "@/types/offer";

export const useOffers = (filters: OfferFilters = {}) =>
  useQuery({
    queryKey: ["offers", filters],
    queryFn: () => listOffers(filters),
    placeholderData: (prev) => prev,
  });

export const useChangeStatus = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status, reason }: { id: number; status: OfferStatus; reason?: string }) =>
      changeStatus(id, status, reason),
    onSuccess: (offer, vars) => {
      qc.invalidateQueries({ queryKey: ["offers"] });
      toast.success(`"${offer.title}" → ${vars.status}`);
    },
    onError: (err) => {
      toast.error(`Falha ao mudar status: ${describeError(err)}`);
    },
  });
};

export const useCreateOffer = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<Offer>) => createOffer(data),
    onSuccess: (offer) => {
      qc.invalidateQueries({ queryKey: ["offers"] });
      toast.success(`Oferta "${offer.title}" criada`);
    },
    onError: (err) => {
      toast.error(`Não foi possível criar: ${describeError(err)}`);
    },
  });
};

export const useUpdateOffer = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<Offer> }) => updateOffer(id, data),
    onSuccess: (offer) => {
      qc.invalidateQueries({ queryKey: ["offers"] });
      toast.success(`"${offer.title}" atualizada`);
    },
    onError: (err) => {
      toast.error(`Não foi possível atualizar: ${describeError(err)}`);
    },
  });
};

export const useArchiveOffer = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => archiveOffer(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["offers"] });
      toast.success("Oferta arquivada");
    },
    onError: (err) => {
      toast.error(`Não foi possível arquivar: ${describeError(err)}`);
    },
  });
};
