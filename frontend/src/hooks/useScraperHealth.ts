import { useQuery } from "@tanstack/react-query";
import { getScraperHealth } from "@/api/scraperHealth";

/** Per-source scraper reliability summary. Invalidated when a batch finishes. */
export const useScraperHealth = () =>
  useQuery({
    queryKey: ["scraper_health"],
    queryFn: getScraperHealth,
  });
