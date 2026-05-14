import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  getProfile,
  getProfileFiles,
  updateProfile,
  type Profile,
} from "@/api/profile";
import { describeError } from "@/api/errors";

export const useProfileFiles = () =>
  useQuery({
    queryKey: ["profile_files"],
    queryFn: getProfileFiles,
    staleTime: 5 * 60 * 1000, // files only change on an explicit upload
  });

/** The editable profile (personal details + scoring keywords). */
export const useProfile = () =>
  useQuery({
    queryKey: ["profile"],
    queryFn: getProfile,
  });

export const useUpdateProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<Profile>) => updateProfile(data),
    onSuccess: (profile) => {
      qc.setQueryData(["profile"], profile);
      qc.invalidateQueries({ queryKey: ["profile_files"] });
      toast.success("Perfil atualizado");
    },
    onError: (err) => {
      toast.error(`Não foi possível guardar: ${describeError(err)}`);
    },
  });
};
