import { api } from "./client";

/** The editable profile — personal details + match-scoring keyword lists. */
export interface Profile {
  name: string | null;
  city: string | null;
  country: string | null;
  email: string | null;
  phone: string | null;
  github: string | null;
  linkedin: string | null;
  start_date: string | null;
  primary_keywords: string[];
  secondary_keywords: string[];
  experimental_keywords: string[];
  positive_title_keywords: string[];
  negative_title_keywords: string[];
  location_bonus_keywords: string[];
  linkedin_keywords: string[];
}

export const getProfile = async (): Promise<Profile> => {
  const res = await api.get<Profile>("/profile");
  return res.data;
};

export const updateProfile = async (data: Partial<Profile>): Promise<Profile> => {
  const res = await api.patch<Profile>("/profile", { profile: data });
  return res.data;
};

export interface ProfileFiles {
  name: string;
  city: string;
  email: string;
  phone: string;
  github: string;
  linkedin: string;
  cv: Record<"pt" | "en", { visual?: string; ats?: string }>;
  cover_letters: Record<"pt" | "en", boolean>;
}

export interface CoverLetterPreview {
  content: string;
  filename: string;
}

export const getProfileFiles = async (): Promise<ProfileFiles> => {
  const res = await api.get<ProfileFiles>("/profile/files");
  return res.data;
};

/** Builds an absolute URL for the CV download so the browser can open it
 *  in a new tab or trigger a download via a normal <a href>. */
export const cvDownloadUrl = (lang: "pt" | "en", format: "visual" | "ats" = "visual"): string => {
  // baseURL is the axios setting — we mirror it here so the <a> tag works without JS.
  const base = (api.defaults.baseURL ?? "/api/v1").replace(/\/$/, "");
  const params = new URLSearchParams({ lang, format });
  return `${base}/profile/cv?${params.toString()}`;
};

export const getCoverLetterPreview = async (
  offerId: number,
  lang: "pt" | "en",
): Promise<CoverLetterPreview> => {
  const res = await api.get<CoverLetterPreview>("/profile/cover_letter", {
    params: { offer_id: offerId, lang },
  });
  return res.data;
};

export const coverLetterDownloadUrl = (offerId: number, lang: "pt" | "en"): string => {
  const base = (api.defaults.baseURL ?? "/api/v1").replace(/\/$/, "");
  const params = new URLSearchParams({ offer_id: String(offerId), lang, download: "true" });
  return `${base}/profile/cover_letter?${params.toString()}`;
};
