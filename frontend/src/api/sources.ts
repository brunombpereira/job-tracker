import { api } from "./client";

export interface SourceRow {
  id: number;
  name: string;
  color: string;
  count: number;
}

export const listSources = async (): Promise<SourceRow[]> => {
  const res = await api.get<SourceRow[]>("/sources");
  return res.data;
};
