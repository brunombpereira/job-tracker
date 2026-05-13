import { useState } from "react";
import type { Offer, OfferStatus } from "@/types/offer";
import { STATUS_TRANSITIONS } from "@/types/offer";
import { StatusBadge } from "./StatusBadge";
import { useArchiveOffer, useChangeStatus } from "@/hooks/useOffers";

const MatchDots = ({ score }: { score: number | null }) => {
  const filled = score ?? 0;
  return (
    <div className="flex gap-1" title={score ? `Match score ${score}/5` : "Sem score"}>
      {Array.from({ length: 5 }, (_, i) => (
        <span
          key={i}
          className={`h-2 w-2 rounded-sm ${i < filled ? "bg-brand-accent" : "bg-slate-200"}`}
        />
      ))}
    </div>
  );
};

interface Props {
  offer: Offer;
  onEdit?: (offer: Offer) => void;
}

export const OfferCard = ({ offer, onEdit }: Props) => {
  const [statusMenuOpen, setStatusMenuOpen] = useState(false);
  const archiveMut = useArchiveOffer();
  const statusMut = useChangeStatus();
  const allowed = STATUS_TRANSITIONS[offer.status] ?? [];

  const onArchive = () => {
    if (!confirm(`Arquivar "${offer.title}"?`)) return;
    archiveMut.mutate(offer.id);
  };

  const onTransition = (next: OfferStatus) => {
    setStatusMenuOpen(false);
    statusMut.mutate({ id: offer.id, status: next });
  };

  return (
    <article className="group rounded-lg border border-slate-200 bg-white p-4 shadow-sm transition hover:shadow-md">
      <header className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-semibold text-brand-dark">
            {offer.url ? (
              <a
                href={offer.url}
                target="_blank"
                rel="noreferrer noopener"
                className="hover:text-brand-accent"
              >
                {offer.title}
              </a>
            ) : (
              offer.title
            )}
          </h3>
          <p className="truncate text-sm text-slate-600">
            {offer.company}
            {offer.location && <span className="text-slate-400"> · {offer.location}</span>}
            {offer.modality && <span className="text-slate-400"> · {offer.modality}</span>}
          </p>
        </div>
        <StatusBadge status={offer.status} />
      </header>

      {offer.stack.length > 0 && (
        <ul className="mt-2 flex flex-wrap gap-1">
          {offer.stack.slice(0, 6).map((tech) => (
            <li
              key={tech}
              className="rounded bg-indigo-50 px-1.5 py-0.5 text-xs text-indigo-700"
            >
              {tech}
            </li>
          ))}
          {offer.stack.length > 6 && (
            <li className="rounded bg-slate-100 px-1.5 py-0.5 text-xs text-slate-500">
              +{offer.stack.length - 6}
            </li>
          )}
        </ul>
      )}

      <footer className="mt-3 flex items-center justify-between text-xs text-slate-500">
        <div className="flex items-center gap-3">
          <MatchDots score={offer.match_score} />
          <span>{offer.found_date}</span>
        </div>

        <div className="flex items-center gap-1 opacity-100 transition md:opacity-0 md:group-hover:opacity-100">
          {allowed.length > 0 && (
            <div className="relative">
              <button
                type="button"
                onClick={() => setStatusMenuOpen((v) => !v)}
                className="rounded p-1 text-slate-500 hover:bg-slate-100 hover:text-slate-700"
                title="Mudar status"
                aria-label="Mudar status"
              >
                <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M3 6a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm1 3a1 1 0 100 2h12a1 1 0 100-2H4z" />
                </svg>
              </button>
              {statusMenuOpen && (
                <>
                  <div
                    className="fixed inset-0 z-10"
                    onClick={() => setStatusMenuOpen(false)}
                    role="presentation"
                  />
                  <ul className="absolute right-0 z-20 mt-1 w-36 rounded-md border border-slate-200 bg-white py-1 shadow-lg">
                    {allowed.map((s) => (
                      <li key={s}>
                        <button
                          type="button"
                          onClick={() => onTransition(s)}
                          className="block w-full px-3 py-1 text-left text-sm capitalize text-slate-700 transition hover:bg-slate-50"
                        >
                          → {s}
                        </button>
                      </li>
                    ))}
                  </ul>
                </>
              )}
            </div>
          )}
          {onEdit && (
            <button
              type="button"
              onClick={() => onEdit(offer)}
              className="rounded p-1 text-slate-500 hover:bg-slate-100 hover:text-slate-700"
              title="Editar"
              aria-label="Editar oferta"
            >
              <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
                <path d="M13.586 3.586a2 2 0 112.828 2.828L7.879 14.95a2 2 0 01-.83.506l-3 1a1 1 0 01-1.265-1.265l1-3a2 2 0 01.506-.83l8.535-8.535z" />
              </svg>
            </button>
          )}
          <button
            type="button"
            onClick={onArchive}
            disabled={archiveMut.isPending}
            className="rounded p-1 text-slate-500 hover:bg-rose-100 hover:text-rose-600 disabled:opacity-40"
            title="Arquivar"
            aria-label="Arquivar oferta"
          >
            <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
              <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zm1 5h12v7a2 2 0 01-2 2H6a2 2 0 01-2-2V9zm4 2a1 1 0 100 2h4a1 1 0 100-2H8z" />
            </svg>
          </button>
        </div>
      </footer>
    </article>
  );
};
