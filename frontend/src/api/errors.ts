import { AxiosError } from "axios";

export interface ApiErrorBody {
  error?: string;
  errors?: string[] | Record<string, string[]>;
}

/** Best-effort human-readable summary of an axios error. */
export function describeError(err: unknown): string {
  if (err instanceof AxiosError) {
    const body = err.response?.data as ApiErrorBody | undefined;
    if (body?.error) return body.error;
    if (Array.isArray(body?.errors)) return body!.errors.join(", ");
    if (body?.errors && typeof body.errors === "object") {
      return Object.entries(body.errors)
        .map(([k, v]) => `${k}: ${(v as string[]).join(", ")}`)
        .join(" · ");
    }
    if (err.response?.status === 404) return "Not found";
    if (err.response?.status && err.response.status >= 500) return "Server error";
    if (err.code === "ERR_NETWORK") return "Network error — backend offline?";
    return err.message;
  }
  return err instanceof Error ? err.message : "Unknown error";
}

/** Returns field → array-of-messages map if backend returned per-field errors. */
export function fieldErrors(err: unknown): Record<string, string[]> {
  if (err instanceof AxiosError) {
    const body = err.response?.data as ApiErrorBody | undefined;
    if (body?.errors && !Array.isArray(body.errors) && typeof body.errors === "object") {
      return body.errors as Record<string, string[]>;
    }
  }
  return {};
}
