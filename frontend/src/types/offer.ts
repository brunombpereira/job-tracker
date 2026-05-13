export type OfferStatus =
  | "new"
  | "interested"
  | "applied"
  | "interview"
  | "offer"
  | "rejected"
  | "archived";

export type OfferModality = "presencial" | "hibrido" | "remoto";

export interface Source {
  id: number;
  name: string;
  color: string;
}

export interface Offer {
  id: number;
  title: string;
  company: string;
  location: string | null;
  modality: OfferModality | null;
  stack: string[];
  url: string | null;
  status: OfferStatus;
  match_score: number | null;
  salary_range: string | null;
  company_size: string | null;
  posted_date: string | null;
  found_date: string;
  applied_date: string | null;
  description: string | null;
  archived: boolean;
  source: Source | null;
}

export interface OfferFilters {
  status?: OfferStatus[];
  modality?: OfferModality;
  match_score_gte?: number;
  match_score_lte?: number;
  location?: string;
  search?: string;
  sort?: string;
  page?: number;
  per_page?: number;
}

export const STATUS_VALUES: OfferStatus[] = [
  "new",
  "interested",
  "applied",
  "interview",
  "offer",
  "rejected",
  "archived",
];

export const MODALITY_VALUES: OfferModality[] = ["presencial", "hibrido", "remoto"];

export const STATUS_TRANSITIONS: Record<OfferStatus, OfferStatus[]> = {
  new:        ["interested", "applied", "rejected", "archived"],
  interested: ["applied", "rejected", "archived"],
  applied:    ["interview", "rejected", "archived"],
  interview:  ["offer", "rejected", "archived"],
  offer:      ["rejected", "archived"],
  rejected:   ["archived"],
  archived:   [],
};
