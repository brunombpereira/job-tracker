// Storage for the shared-secret API token. It's sent as a Bearer header
// on every request (see client.ts) and validated server-side against
// API_ACCESS_TOKEN.
const KEY = "jobtracker_token";

export const getToken = (): string | null => {
  try {
    return localStorage.getItem(KEY);
  } catch {
    return null;
  }
};

export const setToken = (token: string): void => {
  try {
    localStorage.setItem(KEY, token);
  } catch {
    // localStorage unavailable (private mode etc.) — the token simply
    // won't persist; the user re-enters it next load.
  }
};

export const clearToken = (): void => {
  try {
    localStorage.removeItem(KEY);
  } catch {
    // ignore
  }
};
