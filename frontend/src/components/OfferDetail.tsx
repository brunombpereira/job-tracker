import { useState } from "react";
import type { FormEvent } from "react";
import type { Offer } from "@/types/offer";
import { useCreateNote, useDeleteNote, useOfferDetail } from "@/hooks/useOfferDetail";
import { StatusBadge } from "./StatusBadge";

interface Props {
  offer: Offer;
  onEdit?: () => void;
}

const fmtDateTime = (iso: string) =>
  new Date(iso).toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });

const fmtDate = (iso: string | null) =>
  iso ? new Date(iso).toLocaleDateString() : "—";

export const OfferDetail = ({ offer, onEdit }: Props) => {
  const { data, isLoading } = useOfferDetail(offer.id);
  const createNote = useCreateNote();
  const deleteNote = useDeleteNote();
  const [draft, setDraft] = useState("");

  const detail = data ?? { ...offer, notes: [], status_changes: [] };

  const onAddNote = (e: FormEvent) => {
    e.preventDefault();
    if (!draft.trim()) return;
    createNote.mutate(
      { offerId: offer.id, content: draft.trim() },
      { onSuccess: () => setDraft("") },
    );
  };

  return (
    <div className="space-y-6">
      {/* Header summary */}
      <header className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h3 className="text-lg font-semibold text-brand-dark">
            {detail.url ? (
              <a
                href={detail.url}
                target="_blank"
                rel="noreferrer noopener"
                className="hover:text-brand-accent"
              >
                {detail.title}
              </a>
            ) : (
              detail.title
            )}
          </h3>
          <p className="text-sm text-slate-600">
            {detail.company}
            {detail.location && <span className="text-slate-400"> · {detail.location}</span>}
            {detail.modality && <span className="text-slate-400"> · {detail.modality}</span>}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <StatusBadge status={detail.status} />
          {onEdit && (
            <button
              type="button"
              onClick={onEdit}
              className="rounded border border-slate-300 px-2 py-1 text-xs font-medium text-slate-700 transition hover:bg-slate-50"
            >
              Editar
            </button>
          )}
        </div>
      </header>

      {/* Metadata grid */}
      <dl className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm md:grid-cols-3">
        <Cell label="Match score" value={detail.match_score ? `${detail.match_score}/5` : "—"} />
        <Cell label="Salary" value={detail.salary_range ?? "—"} />
        <Cell label="Company size" value={detail.company_size ?? "—"} />
        <Cell label="Posted" value={fmtDate(detail.posted_date)} />
        <Cell label="Found" value={fmtDate(detail.found_date)} />
        <Cell label="Applied" value={fmtDate(detail.applied_date)} />
      </dl>

      {detail.stack.length > 0 && (
        <div>
          <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Stack
          </h4>
          <ul className="flex flex-wrap gap-1.5">
            {detail.stack.map((t) => (
              <li
                key={t}
                className="rounded bg-indigo-50 px-2 py-0.5 text-xs text-indigo-700"
              >
                {t}
              </li>
            ))}
          </ul>
        </div>
      )}

      {detail.description && (
        <div>
          <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Description
          </h4>
          <p className="whitespace-pre-line text-sm text-slate-700">{detail.description}</p>
        </div>
      )}

      {/* Notes */}
      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Notas {detail.notes.length > 0 && `(${detail.notes.length})`}
        </h4>
        <form onSubmit={onAddNote} className="mb-3 flex gap-2">
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            placeholder="Adicionar nota..."
            className="flex-1 rounded border border-slate-300 px-3 py-1.5 text-sm focus:border-brand-accent focus:outline-none"
          />
          <button
            type="submit"
            disabled={!draft.trim() || createNote.isPending}
            className="rounded bg-brand-accent px-3 py-1.5 text-sm font-medium text-white transition hover:bg-brand disabled:opacity-50"
          >
            Adicionar
          </button>
        </form>
        {isLoading ? (
          <p className="text-xs text-slate-400">A carregar...</p>
        ) : detail.notes.length === 0 ? (
          <p className="text-xs text-slate-400">Sem notas.</p>
        ) : (
          <ul className="space-y-2">
            {detail.notes.map((note) => (
              <li
                key={note.id}
                className="group flex items-start justify-between gap-2 rounded border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700"
              >
                <div className="flex-1">
                  <p className="whitespace-pre-line">{note.content}</p>
                  <p className="mt-1 text-[10px] uppercase tracking-wide text-slate-400">
                    {fmtDateTime(note.created_at)}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    deleteNote.mutate({ offerId: offer.id, noteId: note.id })
                  }
                  disabled={deleteNote.isPending}
                  className="rounded p-1 text-slate-400 opacity-0 transition hover:bg-rose-100 hover:text-rose-600 group-hover:opacity-100 disabled:opacity-40"
                  aria-label="Apagar nota"
                  title="Apagar nota"
                >
                  <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                  </svg>
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* Status timeline */}
      <section>
        <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Histórico de status {detail.status_changes.length > 0 && `(${detail.status_changes.length})`}
        </h4>
        {detail.status_changes.length === 0 ? (
          <p className="text-xs text-slate-400">Ainda sem transições gravadas.</p>
        ) : (
          <ol className="space-y-1.5 border-l-2 border-slate-200 pl-4">
            {detail.status_changes.map((sc) => (
              <li key={sc.id} className="text-sm text-slate-700">
                <span className="inline-block min-w-[8rem] text-xs uppercase tracking-wide text-slate-400">
                  {fmtDateTime(sc.created_at)}
                </span>
                {sc.from_status ? (
                  <>
                    <span className="capitalize text-slate-500">{sc.from_status}</span>
                    <span className="mx-1.5 text-slate-300">→</span>
                  </>
                ) : null}
                <span className="font-medium capitalize text-slate-800">{sc.to_status}</span>
                {sc.reason && <span className="ml-2 text-xs text-slate-500">— {sc.reason}</span>}
              </li>
            ))}
          </ol>
        )}
      </section>
    </div>
  );
};

const Cell = ({ label, value }: { label: string; value: string }) => (
  <div>
    <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">{label}</dt>
    <dd className="text-sm text-slate-800">{value}</dd>
  </div>
);
