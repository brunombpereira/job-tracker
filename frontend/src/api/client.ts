import axios from "axios";
import { clearToken, getToken } from "./token";

const baseURL = import.meta.env.VITE_API_URL ?? "/api/v1";

export const api = axios.create({
  baseURL,
  headers: { "Content-Type": "application/json" },
});

// Attach the shared-secret token (when present) to every request.
api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// A 401 means the stored token is missing or no longer valid — drop it
// and reload so the AuthGate falls back to the login screen. The /auth
// probe skips the gate and never 401s, so this can't loop.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearToken();
      window.location.reload();
    }
    return Promise.reject(error);
  },
);
