import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { useProfile, useUpdateProfile } from "@/hooks/useProfile";
import type { Profile } from "@/api/profile";

// Personal details — free-text fields, used to fill cover-letter tokens.
const DETAIL_FIELDS: { key: keyof Profile; label: string; placeholder?: string }[] = [
  { key: "name", label: "Nome" },
  { key: "city", label: "Cidade" },
  { key: "country", label: "País" },
  { key: "email", label: "Email" },
  { key: "phone", label: "Telefone" },
  { key: "github", label: "GitHub" },
  { key: "linkedin", label: "LinkedIn" },
  { key: "start_date", label: "Disponibilidade", placeholder: "ex.: imediato" },
];

// Keyword lists — edited as comma-separated text, stored as arrays.
const KEYWORD_FIELDS: { key: keyof Profile; label: string; hint: string }[] = [
  { key: "primary_keywords", label: "Stack principal", hint: "tecnologias do dia-a-dia — maior peso no match score" },
  { key: "secondary_keywords", label: "Stack secundária", hint: "domínas mas não são o foco" },
  { key: "experimental_keywords", label: "Stack experimental", hint: "tecnologias que tocaste de leve" },
  { key: "positive_title_keywords", label: "Títulos a valorizar", hint: "ex.: junior, trainee, graduate" },
  { key: "negative_title_keywords", label: "Títulos a penalizar", hint: "ex.: senior, 5+ years" },
  { key: "location_bonus_keywords", label: "Localizações a valorizar", hint: "cidades, países, remote, hybrid…" },
  { key: "linkedin_keywords", label: "Pesquisas no LinkedIn", hint: "uma pesquisa por entrada — ex.: junior developer" },
];

type FormState = Record<string, string>;

const toForm = (p: Profile): FormState => {
  const f: FormState = {};
  for (const { key } of DETAIL_FIELDS) f[key] = (p[key] as string | null) ?? "";
  for (const { key } of KEYWORD_FIELDS) f[key] = ((p[key] as string[]) ?? []).join(", ");
  return f;
};

const toPayload = (f: FormState): Partial<Profile> => {
  const payload: Record<string, unknown> = {};
  for (const { key } of DETAIL_FIELDS) payload[key] = f[key]?.trim() || null;
  for (const { key } of KEYWORD_FIELDS) {
    payload[key] = (f[key] ?? "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
  }
  return payload as Partial<Profile>;
};

const inputClass =
  "block w-full rounded-lg border border-edge-strong bg-surface-raised px-3 py-2 text-sm text-ink placeholder:text-ink-muted focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-soft";

export const Settings = () => {
  const { data, isLoading, error } = useProfile();
  const update = useUpdateProfile();
  const [form, setForm] = useState<FormState>({});

  useEffect(() => {
    if (data) setForm(toForm(data));
  }, [data]);

  const set = (key: string) => (e: { target: { value: string } }) =>
    setForm((prev) => ({ ...prev, [key]: e.target.value }));

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    update.mutate(toPayload(form));
  };

  if (isLoading) return <p className="text-sm text-ink-muted">A carregar perfil…</p>;
  if (error) {
    return (
      <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-700 dark:border-rose-900 dark:bg-rose-950/40 dark:text-rose-200">
        Erro a carregar o perfil. Verifica que o backend está a correr.
      </p>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-8">
      <section>
        <h2 className="font-serif text-lg text-ink">Dados pessoais</h2>
        <p className="mt-0.5 text-xs text-ink-muted">
          Preenchem os campos das cartas de apresentação geradas.
        </p>
        <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
          {DETAIL_FIELDS.map(({ key, label, placeholder }) => (
            <label key={key} className="block">
              <span className="mb-1 block text-xs font-medium text-ink-soft">{label}</span>
              <input
                value={form[key] ?? ""}
                onChange={set(key)}
                placeholder={placeholder}
                className={inputClass}
              />
            </label>
          ))}
        </div>
      </section>

      <section>
        <h2 className="font-serif text-lg text-ink">Match score &amp; pesquisa</h2>
        <p className="mt-0.5 text-xs text-ink-muted">
          Listas separadas por vírgulas. Afinam o match score das ofertas e as
          pesquisas automáticas no LinkedIn.
        </p>
        <div className="mt-4 space-y-3">
          {KEYWORD_FIELDS.map(({ key, label, hint }) => (
            <label key={key} className="block">
              <span className="mb-1 block text-xs font-medium text-ink-soft">
                {label} <span className="font-normal text-ink-muted">— {hint}</span>
              </span>
              <input value={form[key] ?? ""} onChange={set(key)} className={inputClass} />
            </label>
          ))}
        </div>
      </section>

      <div className="flex justify-end border-t border-edge pt-4">
        <button
          type="submit"
          disabled={update.isPending}
          className="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white shadow-soft transition hover:bg-accent-deep disabled:opacity-50"
        >
          {update.isPending ? "A guardar…" : "Guardar perfil"}
        </button>
      </div>
    </form>
  );
};
