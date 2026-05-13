import { api } from "./client";
import type { Note, Offer, OfferDetail, OfferFilters, OfferStatus } from "@/types/offer";

const buildParams = (filters: OfferFilters) => {
  const params: Record<string, string | number> = {};
  if (filters.status?.length) params.status = filters.status.join(",");
  if (filters.modality) params.modality = filters.modality;
  if (filters.match_score_gte) params.match_score_gte = filters.match_score_gte;
  if (filters.match_score_lte) params.match_score_lte = filters.match_score_lte;
  if (filters.location) params.location = filters.location;
  if (filters.source_id) params.source_id = filters.source_id;
  if (filters.search) params.search = filters.search;
  if (filters.sort) params.sort = filters.sort;
  if (filters.page) params.page = filters.page;
  if (filters.per_page) params.per_page = filters.per_page;
  if (filters.include_archived) params.include_archived = "true";
  return params;
};

export interface OffersResponse {
  offers: Offer[];
  total: number;
  page: number;
  perPage: number;
}

export const listOffers = async (filters: OfferFilters = {}): Promise<OffersResponse> => {
  const res = await api.get<Offer[]>("/offers", { params: buildParams(filters) });
  return {
    offers: res.data,
    total: Number(res.headers["total-count"] ?? res.data.length),
    page: Number(res.headers["current-page"] ?? 1),
    perPage: Number(res.headers["per-page"] ?? 25),
  };
};

export const getOffer = async (id: number): Promise<OfferDetail> => {
  const res = await api.get<OfferDetail>(`/offers/${id}`);
  return res.data;
};

export const createNote = async (offerId: number, content: string): Promise<Note> => {
  const res = await api.post<Note>(`/offers/${offerId}/notes`, { content });
  return res.data;
};

export const deleteNote = async (offerId: number, noteId: number): Promise<void> => {
  await api.delete(`/offers/${offerId}/notes/${noteId}`);
};

export const createOffer = async (data: Partial<Offer>): Promise<Offer> => {
  const res = await api.post<Offer>("/offers", { offer: data });
  return res.data;
};

export const updateOffer = async (id: number, data: Partial<Offer>): Promise<Offer> => {
  const res = await api.patch<Offer>(`/offers/${id}`, { offer: data });
  return res.data;
};

export const changeStatus = async (
  id: number,
  status: OfferStatus,
  reason?: string,
): Promise<Offer> => {
  const res = await api.patch<Offer>(`/offers/${id}/status`, { status, reason });
  return res.data;
};

export const archiveOffer = async (id: number): Promise<void> => {
  await api.delete(`/offers/${id}`);
};
