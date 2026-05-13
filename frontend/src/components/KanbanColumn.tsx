import { useDroppable } from "@dnd-kit/core";
import type { Offer, OfferStatus } from "@/types/offer";
import { KanbanCard } from "./KanbanCard";

interface Props {
  status: OfferStatus;
  title: string;
  hint: string;
  offers: Offer[];
  onCardClick?: (offer: Offer) => void;
  isReceiving?: boolean;
}

/**
 * Per-status colour palette for the column's accent dot. Background of
 * the column body stays surface-raised — only the dot, count chip, and
 * drop-zone tint pick up the status colour.
 */
const STATUS_TONE: Record<OfferStatus, { dot: string; tint: string }> = {
  new:        { dot: "bg-blue-400",    tint: "bg-blue-50/40    dark:bg-blue-900/20" },
  interested: { dot: "bg-amber-400",   tint: "bg-amber-50/40   dark:bg-amber-900/20" },
  applied:    { dot: "bg-emerald-400", tint: "bg-emerald-50/40 dark:bg-emerald-900/20" },
  interview:  { dot: "bg-violet-400",  tint: "bg-violet-50/40  dark:bg-violet-900/20" },
  offer:      { dot: "bg-pink-400",    tint: "bg-pink-50/40    dark:bg-pink-900/20" },
  rejected:   { dot: "bg-rose-400",    tint: "bg-rose-50/40    dark:bg-rose-900/20" },
  archived:   { dot: "bg-stone-400",   tint: "bg-surface-sunken" },
};

export const KanbanColumn = ({
  status,
  title,
  hint,
  offers,
  onCardClick,
  isReceiving,
}: Props) => {
  const { setNodeRef, isOver } = useDroppable({ id: status });
  const tone = STATUS_TONE[status];
  const empty = offers.length === 0;

  return (
    <div className="flex min-w-[280px] flex-1 flex-col">
      <header className="mb-3 flex items-baseline justify-between gap-2 px-1">
        <div className="flex items-center gap-2">
          <span className={`h-2 w-2 rounded-full ${tone.dot}`} aria-hidden="true" />
          <h3 className="font-serif text-sm text-ink">{title}</h3>
          <span className="rounded-full bg-surface-sunken px-2 py-0.5 text-[10px] font-semibold text-ink-soft">
            {offers.length}
          </span>
        </div>
        <p className="hidden text-[10px] text-ink-muted lg:block">{hint}</p>
      </header>

      <div
        ref={setNodeRef}
        className={`flex min-h-[6rem] flex-1 flex-col gap-2 rounded-xl border border-dashed p-2.5 transition ${
          isOver
            ? isReceiving
              ? "border-emerald-400 bg-emerald-50/40 dark:bg-emerald-900/20"
              : "border-rose-400 bg-rose-50/40 dark:bg-rose-900/20"
            : `border-edge ${empty ? tone.tint : ""}`
        }`}
      >
        {empty ? (
          <p className="my-6 text-center text-[11px] text-ink-muted">Nada aqui ainda</p>
        ) : (
          offers.map((offer) => (
            <KanbanCard key={offer.id} offer={offer} onClick={onCardClick} />
          ))
        )}
      </div>
    </div>
  );
};
