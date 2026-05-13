import { api } from "./client";

export interface ScraperRun {
  id: number;
  source_name: string;
  status: "pending" | "running" | "succeeded" | "failed";
  offers_found: number;
  offers_created: number;
  offers_skipped: number;
  params: Record<string, unknown>;
  error_message: string | null;
  started_at: string | null;
  finished_at: string | null;
  created_at: string;
}

export interface ScraperRunsResponse {
  sources: string[];
  runs: ScraperRun[];
}

export const listScraperRuns = async (): Promise<ScraperRunsResponse> => {
  const res = await api.get<ScraperRunsResponse>("/scraper_runs");
  return res.data;
};

export const enqueueScraperRun = async (
  source: string,
  params: Record<string, string> = {},
): Promise<void> => {
  await api.post("/scraper_runs", { source, params });
};
