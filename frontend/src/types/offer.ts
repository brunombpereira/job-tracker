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
  location?: string;
  search?: string;
  sort?: string;
  page?: number;
  per_page?: number;
}
