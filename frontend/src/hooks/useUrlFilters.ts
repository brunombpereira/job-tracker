import { useCallback, useEffect, useState } from "react";
import type { OfferFilters, OfferModality, OfferStatus } from "@/types/offer";
import { MODALITY_VALUES, STATUS_VALUES } from "@/types/offer";

export type ViewMode = "list" | "kanban";

export interface UrlState {
  filters: OfferFilters;
  view: ViewMode;
  searchInput: string;
}

const DEFAULT_STATE: UrlState = {
  filters: { sort: "match_score:desc", per_page: 25, page: 1 },
  view: "list",
  searchInput: "",
};

const isStatus = (s: string): s is OfferStatus =>
  STATUS_VALUES.includes(s as OfferStatus);

const isModality = (m: string): m is OfferModality =>
  MODALITY_VALUES.includes(m as OfferModality);

/** Parse URLSearchParams into a typed UrlState. Unknown keys ignored. */
export function parseSearchParams(params: URLSearchParams): UrlState {
  const filters: OfferFilters = { ...DEFAULT_STATE.filters };

  const status = params.get("status");
  if (status) {
    const arr = status.split(",").filter(isStatus);
    if (arr.length) filters.status = arr;
  }

  const modality = params.get("modality");
  if (modality && isModality(modality)) filters.modality = modality;

  const gte = params.get("match_score_gte");
  if (gte) filters.match_score_gte = Number(gte);

  const lte = params.get("match_score_lte");
  if (lte) filters.match_score_lte = Number(lte);

  const location = params.get("location");
  if (location) filters.location = location;

  const sourceId = params.get("source_id");
  if (sourceId) filters.source_id = Number(sourceId);

  const search = params.get("search");
  if (search) filters.search = search;

  const sort = params.get("sort");
  if (sort) filters.sort = sort;

  const page = params.get("page");
  if (page) filters.page = Number(page);

  const perPage = params.get("per_page");
  if (perPage) filters.per_page = Number(perPage);

  if (params.get("include_archived") === "true") filters.include_archived = true;

  const view = params.get("view") === "kanban" ? "kanban" : "list";

  return { filters, view, searchInput: filters.search ?? "" };
}

/** Serialize UrlState into URLSearchParams (omit defaults). */
export function toSearchParams(state: UrlState): URLSearchParams {
  const p = new URLSearchParams();
  const f = state.filters;

  if (f.status?.length) p.set("status", f.status.join(","));
  if (f.modality) p.set("modality", f.modality);
  if (f.match_score_gte != null) p.set("match_score_gte", String(f.match_score_gte));
  if (f.match_score_lte != null) p.set("match_score_lte", String(f.match_score_lte));
  if (f.location) p.set("location", f.location);
  if (f.source_id) p.set("source_id", String(f.source_id));
  if (f.search) p.set("search", f.search);
  if (f.sort && f.sort !== "match_score:desc") p.set("sort", f.sort);
  if (f.page && f.page !== 1) p.set("page", String(f.page));
  if (f.per_page && f.per_page !== 25) p.set("per_page", String(f.per_page));
  if (f.include_archived) p.set("include_archived", "true");
  if (state.view === "kanban") p.set("view", "kanban");

  return p;
}

/**
 * Single source of truth for filters/view/search input — synced to URL
 * search params via history.replaceState (no router required, no reload).
 */
export function useUrlFilters() {
  const [state, setState] = useState<UrlState>(() => {
    if (typeof window === "undefined") return DEFAULT_STATE;
    return parseSearchParams(new URLSearchParams(window.location.search));
  });

  // Write to URL whenever state changes
  useEffect(() => {
    if (typeof window === "undefined") return;
    const p = toSearchParams(state);
    const qs = p.toString();
    const next = qs ? `${window.location.pathname}?${qs}` : window.location.pathname;
    if (next !== window.location.pathname + window.location.search) {
      window.history.replaceState({}, "", next);
    }
  }, [state]);

  // Listen to popstate (browser back/forward) so we re-sync from URL
  useEffect(() => {
    if (typeof window === "undefined") return;
    const onPop = () => {
      setState(parseSearchParams(new URLSearchParams(window.location.search)));
    };
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);

  const setFilters = useCallback(
    (filters: OfferFilters) => setState((prev) => ({ ...prev, filters })),
    [],
  );
  const setView = useCallback(
    (view: ViewMode) => setState((prev) => ({ ...prev, view })),
    [],
  );
  const setSearchInput = useCallback(
    (searchInput: string) => setState((prev) => ({ ...prev, searchInput })),
    [],
  );

  return {
    ...state,
    setFilters,
    setView,
    setSearchInput,
  };
}
