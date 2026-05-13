import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import type { Offer, OfferModality, OfferStatus } from "@/types/offer";
import { MODALITY_VALUES, STATUS_VALUES } from "@/types/offer";
import { useCreateOffer, useUpdateOffer } from "@/hooks/useOffers";

interface Props {
  offer?: Offer;
  onSaved: () => void;
  onCancel: () => void;
}

type FormState = {
  title: string;
  company: string;
  location: string;
  modality: OfferModality | "";
  url: string;
  status: OfferStatus;
  match_score: string;
  salary_range: string;
  company_size: string;
  posted_date: string;
  description: string;
  stack: string;
};

const empty: FormState = {
  title: "",
  company: "",
  location: "",
  modality: "",
  url: "",
  status: "new",
  match_score: "",
  salary_range: "",
  company_size: "",
  posted_date: "",
  description: "",
  stack: "",
};

const offerToForm = (offer: Offer): FormState => ({
  title: offer.title,
  company: offer.company,
  location: offer.location ?? "",
  modality: offer.modality ?? "",
  url: offer.url ?? "",
  status: offer.status,
  match_score: offer.match_score?.toString() ?? "",
  salary_range: offer.salary_range ?? "",
  company_size: offer.company_size ?? "",
  posted_date: offer.posted_date ?? "",
  description: offer.description ?? "",
  stack: offer.stack.join(", "),
});

export const OfferForm = ({ offer, onSaved, onCancel }: Props) => {
  const [form, setForm] = useState<FormState>(offer ? offerToForm(offer) : empty);
  const [error, setError] = useState<string | null>(null);
  const createMut = useCreateOffer();
  const updateMut = useUpdateOffer();
  const submitting = createMut.isPending || updateMut.isPending;

  useEffect(() => {
    setForm(offer ? offerToForm(offer) : empty);
    setError(null);
  }, [offer]);

  const set =
    <K extends keyof FormState>(key: K) =>
    (e: { target: { value: string } }) =>
      setForm((prev) => ({ ...prev, [key]: e.target.value }));

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);

    const payload: Partial<Offer> = {
      title: form.title.trim(),
      company: form.company.trim(),
      location: form.location.trim() || null,
      modality: form.modality || null,
      url: form.url.trim() || null,
      status: form.status,
      match_score: form.match_score ? Number(form.match_score) : null,
      salary_range: form.salary_range.trim() || null,
      company_size: form.company_size.trim() || null,
      posted_date: form.posted_date || null,
      description: form.description.trim() || null,
      stack: form.stack
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
    };

    try {
      if (offer) {
        await updateMut.mutateAsync({ id: offer.id, data: payload });
      } else {
        await createMut.mutateAsync(payload);
      }
      onSaved();
    } catch (err) {
      const msg =
        (err as { response?: { data?: { errors?: unknown; error?: string } } }).response?.data
          ?.error ?? "Falhou a gravar oferta.";
      setError(String(msg));
    }
  };

  const inputClass =
    "block w-full rounded border border-slate-300 px-3 py-2 text-sm focus:border-brand-accent focus:outline-none";

  return (
    <form onSubmit={onSubmit} className="space-y-3">
      {error && (
        <div className="rounded bg-rose-50 px-3 py-2 text-sm text-rose-700">{error}</div>
      )}

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Title *</span>
          <input value={form.title} onChange={set("title")} required className={inputClass} />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Company *</span>
          <input value={form.company} onChange={set("company")} required className={inputClass} />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Location</span>
          <input value={form.location} onChange={set("location")} className={inputClass} />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Modality</span>
          <select value={form.modality} onChange={set("modality")} className={inputClass}>
            <option value="">—</option>
            {MODALITY_VALUES.map((m) => (
              <option key={m} value={m}>
                {m}
              </option>
            ))}
          </select>
        </label>
        <label className="block md:col-span-2">
          <span className="mb-1 block text-xs font-medium text-slate-700">URL</span>
          <input
            type="url"
            value={form.url}
            onChange={set("url")}
            placeholder="https://..."
            className={inputClass}
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Status</span>
          <select value={form.status} onChange={set("status")} className={inputClass}>
            {STATUS_VALUES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Match score (1-5)</span>
          <input
            type="number"
            min={1}
            max={5}
            value={form.match_score}
            onChange={set("match_score")}
            className={inputClass}
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Salary range</span>
          <input
            value={form.salary_range}
            onChange={set("salary_range")}
            placeholder="e.g. €25k–€32k"
            className={inputClass}
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">Company size</span>
          <input
            value={form.company_size}
            onChange={set("company_size")}
            placeholder="e.g. 11-50"
            className={inputClass}
          />
        </label>
        <label className="block md:col-span-2">
          <span className="mb-1 block text-xs font-medium text-slate-700">
            Stack (comma-separated)
          </span>
          <input
            value={form.stack}
            onChange={set("stack")}
            placeholder="Ruby, Rails, React"
            className={inputClass}
          />
        </label>
        <label className="block md:col-span-2">
          <span className="mb-1 block text-xs font-medium text-slate-700">Description</span>
          <textarea
            value={form.description}
            onChange={set("description")}
            rows={4}
            className={inputClass}
          />
        </label>
      </div>

      <div className="flex justify-end gap-2 border-t border-slate-200 pt-3">
        <button
          type="button"
          onClick={onCancel}
          className="rounded border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={submitting}
          className="rounded bg-brand-accent px-3 py-1.5 text-sm font-medium text-white transition hover:bg-brand disabled:opacity-50"
        >
          {submitting ? "A gravar..." : offer ? "Atualizar oferta" : "Criar oferta"}
        </button>
      </div>
    </form>
  );
};
