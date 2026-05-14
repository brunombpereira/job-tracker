import { api } from "./client";

export interface AuthStatus {
  /** Whether the server has a shared-secret token configured. */
  required: boolean;
  /** Whether the current request (token from localStorage) is accepted. */
  authenticated: boolean;
}

export const getAuthStatus = async (): Promise<AuthStatus> => {
  const res = await api.get<AuthStatus>("/auth");
  return res.data;
};
