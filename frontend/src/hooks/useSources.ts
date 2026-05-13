import { useQuery } from "@tanstack/react-query";
import { listSources } from "@/api/sources";

export const useSources = () =>
  useQuery({
    queryKey: ["sources"],
    queryFn: listSources,
    staleTime: 60_000, // sources change rarely — 1 min is plenty
  });
