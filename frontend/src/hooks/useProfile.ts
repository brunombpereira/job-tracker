import { useQuery } from "@tanstack/react-query";
import { getProfileFiles } from "@/api/profile";

export const useProfileFiles = () =>
  useQuery({
    queryKey: ["profile_files"],
    queryFn: getProfileFiles,
    staleTime: 5 * 60 * 1000, // files only change when Bruno drops a new PDF
  });
