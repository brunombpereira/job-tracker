import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { enqueueScraperRun, listScraperRuns } from "@/api/scrapers";
import { describeError } from "@/api/errors";

export const useScraperRuns = () =>
  useQuery({
    queryKey: ["scraper_runs"],
    queryFn: listScraperRuns,
    // Poll while at least one run is pending/running, otherwise back off
    refetchInterval: (q) => {
      const runs = q.state.data?.runs ?? [];
      return runs.some((r) => r.status === "pending" || r.status === "running")
        ? 3_000
        : false;
    },
  });

export const useEnqueueScraperRun = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ source, params }: { source: string; params?: Record<string, string> }) =>
      enqueueScraperRun(source, params),
    onSuccess: (_v, vars) => {
      qc.invalidateQueries({ queryKey: ["scraper_runs"] });
      qc.invalidateQueries({ queryKey: ["offers"] });
      toast.success(`Scrape de "${vars.source}" enfileirado`);
    },
    onError: (err) => {
      toast.error(`Não foi possível enfileirar: ${describeError(err)}`);
    },
  });
};
