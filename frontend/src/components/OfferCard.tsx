import type { Offer } from "@/types/offer";
import { StatusBadge } from "./StatusBadge";

const MatchDots = ({ score }: { score: number | null }) => {
  const filled = score ?? 0;
  return (
    <div className="flex gap-1">
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
}

export const OfferCard = ({ offer }: Props) => (
  <article className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm transition hover:shadow">
    <header className="flex items-start justify-between gap-2">
      <div>
        <h3 className="font-semibold text-brand-dark">
          {offer.url ? (
            <a href={offer.url} target="_blank" rel="noreferrer noopener" className="hover:text-brand-accent">
              {offer.title}
            </a>
          ) : (
            offer.title
          )}
        </h3>
        <p className="text-sm text-slate-600">
          {offer.company}
          {offer.location && <span className="text-slate-400"> · {offer.location}</span>}
          {offer.modality && <span className="text-slate-400"> · {offer.modality}</span>}
        </p>
      </div>
      <StatusBadge status={offer.status} />
    </header>

    {offer.stack.length > 0 && (
      <ul className="mt-2 flex flex-wrap gap-1">
        {offer.stack.slice(0, 5).map((tech) => (
          <li key={tech} className="rounded bg-indigo-50 px-1.5 py-0.5 text-xs text-indigo-700">
            {tech}
          </li>
        ))}
      </ul>
    )}

    <footer className="mt-3 flex items-center justify-between text-xs text-slate-500">
      <MatchDots score={offer.match_score} />
      <span>{offer.found_date}</span>
    </footer>
  </article>
);
