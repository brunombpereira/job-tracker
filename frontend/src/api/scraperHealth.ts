import { api } from "./client";

export type HealthStatus = "ok" | "degraded" | "down" | "unknown";

export interface SourceHealth {
  key: string;
  display_name: string;
  color: string;
  status: HealthStatus;
  last_run_at: string | null;
  last_status: string | null;
  last_found: number | null;
  consecutive_failures: number;
  consecutive_zero_finds: number;
}

export const getScraperHealth = async (): Promise<SourceHealth[]> => {
  const res = await api.get<{ sources: SourceHealth[] }>("/scraper_runs/health");
  return res.data.sources;
};
