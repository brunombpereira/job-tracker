import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { api } from "@/api/client";
import { describeError } from "@/api/errors";

interface ImportedOffer {
  id: number;
  title: string;
  company: string;
}

const importUrl = async (url: string): Promise<ImportedOffer> => {
  const res = await api.post<ImportedOffer>("/offers/import_url", { url });
  return res.data;
};

export const UrlImportPanel = () => {
  const [url, setUrl] = useState("");
  const qc = useQueryClient();

  const mutation = useMutation({
    mutationFn: importUrl,
    onSuccess: (offer) => {
      qc.invalidateQueries({ queryKey: ["offers"] });
      toast.success(`Importada: ${offer.company} · ${offer.title}`);
      setUrl("");
    },
    onError: (err) => toast.error(`Não foi possível importar: ${describeError(err)}`),
  });

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!url.trim()) return;
    mutation.mutate(url.trim());
  };

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-4">
      <h3 className="text-sm font-semibold text-slate-900">
        Importar de um URL
      </h3>
      <p className="mt-1 text-xs text-slate-500">
        Cola o link de uma oferta no LinkedIn, Indeed, Glassdoor, ou qualquer página de
        emprego com <code className="rounded bg-slate-100 px-1">JobPosting</code> JSON-LD.
        Lemos a meta uma vez e criamos a entry.
      </p>

      <form onSubmit={onSubmit} className="mt-3 flex flex-col gap-2 sm:flex-row">
        <input
          type="url"
          required
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          placeholder="https://www.linkedin.com/jobs/view/…"
          className="block w-full rounded border border-slate-300 px-3 py-2 text-sm focus:border-brand-accent focus:outline-none focus:ring-1 focus:ring-brand-accent"
          disabled={mutation.isPending}
        />
        <button
          type="submit"
          disabled={mutation.isPending || !url.trim()}
          className="inline-flex items-center justify-center rounded bg-brand-accent px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-brand disabled:cursor-not-allowed disabled:opacity-50"
        >
          {mutation.isPending ? "A importar…" : "Importar"}
        </button>
      </form>
    </section>
  );
};
