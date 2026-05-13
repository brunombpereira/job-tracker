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
          className={`h-2 w-2 rounded-sm ${i < filled ? "bg-accent" : "bg-edge"}`}
        />
      ))}
    </div>
  );
};

interface Props {
  offer: Offer;
  onEdit?: (offer: Offer) => void;
  onOpen?: (offer: Offer) => void;
}

export const OfferCard = ({ offer, onEdit, onOpen }: Props) => {
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
    <article className="group rounded-xl border border-edge bg-surface-raised p-5 shadow-soft transition hover:shadow-raise">
      <header className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-serif text-base text-ink">
            {onOpen ? (
              <button
                type="button"
                onClick={() => onOpen(offer)}
                className="text-left hover:text-accent"
              >
                {offer.title}
              </button>
            ) : offer.url ? (
              <a
                href={offer.url}
                target="_blank"
                rel="noreferrer noopener"
                className="hover:text-accent"
              >
                {offer.title}
              </a>
            ) : (
              offer.title
            )}
          </h3>
          <p className="mt-0.5 truncate text-sm text-ink-soft">
            <span className="font-medium">{offer.company}</span>
            {offer.location && <span className="text-ink-muted"> · {offer.location}</span>}
            {offer.modality && <span className="text-ink-muted"> · {offer.modality}</span>}
          </p>
        </div>
        <StatusBadge status={offer.status} />
      </header>

      {offer.stack.length > 0 && (
        <ul className="mt-3 flex flex-wrap gap-1">
          {offer.stack.slice(0, 6).map((tech) => (
            <li
              key={tech}
              className="rounded-md bg-accent-ghost px-2 py-0.5 text-xs text-accent-deep dark:bg-accent-soft/30"
            >
              {tech}
            </li>
          ))}
          {offer.stack.length > 6 && (
            <li className="rounded-md bg-surface-sunken px-2 py-0.5 text-xs text-ink-muted">
              +{offer.stack.length - 6}
            </li>
          )}
        </ul>
      )}

      <footer className="mt-4 flex items-center justify-between text-xs text-ink-muted">
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
                className="rounded p-1 text-ink-muted hover:bg-surface-sunken hover:text-ink-soft"
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
                  <ul className="absolute right-0 z-20 mt-1 w-36 rounded-md border border-edge bg-surface-raised py-1 shadow-lg">
                    {allowed.map((s) => (
                      <li key={s}>
                        <button
                          type="button"
                          onClick={() => onTransition(s)}
                          className="block w-full px-3 py-1 text-left text-sm capitalize text-ink-soft transition hover:bg-surface"
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
              className="rounded p-1 text-ink-muted hover:bg-surface-sunken hover:text-ink-soft"
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
            className="rounded p-1 text-ink-muted hover:bg-rose-100 hover:text-rose-600 disabled:opacity-40"
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
