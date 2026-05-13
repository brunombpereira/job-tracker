import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  listOffers,
  changeStatus,
  createOffer,
  updateOffer,
  archiveOffer,
} from "@/api/offers";
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
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["offers"] });
    },
  });
};

export const useCreateOffer = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<Offer>) => createOffer(data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["offers"] }),
  });
};

export const useUpdateOffer = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<Offer> }) => updateOffer(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["offers"] }),
  });
};

export const useArchiveOffer = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => archiveOffer(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["offers"] }),
  });
};
