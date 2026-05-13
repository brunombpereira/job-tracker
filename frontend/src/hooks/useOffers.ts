import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { listOffers, changeStatus } from "@/api/offers";
import type { OfferFilters, OfferStatus } from "@/types/offer";

export const useOffers = (filters: OfferFilters = {}) =>
  useQuery({
    queryKey: ["offers", filters],
    queryFn: () => listOffers(filters),
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
