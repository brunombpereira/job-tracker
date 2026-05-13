import { api } from "./client";

export type BatchStatus = "pending" | "running" | "succeeded" | "partial" | "failed";
export type RunStatus = "pending" | "running" | "succeeded" | "failed";

export interface SourceMeta {
  key: string;
  display_name: string;
  color: string;
  tag: string;
  ready: boolean;
  requires_env: string[];
  default_params: Record<string, unknown>;
}

export interface BatchRun {
  id: number;
  source_name: string;
  status: RunStatus;
  offers_found: number;
  offers_created: number;
  offers_skipped: number;
  error_message: string | null;
  started_at: string | null;
  finished_at: string | null;
}

export interface SearchBatch {
  id: number;
  status: BatchStatus;
  sources_requested: string[];
  offers_found: number;
  offers_created: number;
  offers_skipped: number;
  started_at: string | null;
  finished_at: string | null;
  created_at: string;
  runs: BatchRun[];
}

export interface SearchBatchesIndex {
  sources: SourceMeta[];
  batches: SearchBatch[];
}

export const listSearchBatches = async (): Promise<SearchBatchesIndex> => {
  const res = await api.get<SearchBatchesIndex>("/search_batches");
  return res.data;
};

export const getSearchBatch = async (id: number): Promise<SearchBatch> => {
  const res = await api.get<SearchBatch>(`/search_batches/${id}`);
  return res.data;
};

export interface CreateBatchInput {
  sources?: string[];
  params_by_source?: Record<string, Record<string, unknown>>;
}

export const createSearchBatch = async (input: CreateBatchInput = {}): Promise<SearchBatch> => {
  const res = await api.post<SearchBatch>("/search_batches", input);
  return res.data;
};

export const isTerminalStatus = (s: BatchStatus): boolean =>
  s === "succeeded" || s === "partial" || s === "failed";
