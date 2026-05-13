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

const STATUS_ACCENT: Record<OfferStatus, string> = {
  new:        "border-blue-200    bg-blue-50    dark:border-blue-900    dark:bg-blue-950/40",
  interested: "border-amber-200   bg-amber-50   dark:border-amber-900   dark:bg-amber-950/40",
  applied:    "border-emerald-200 bg-emerald-50 dark:border-emerald-900 dark:bg-emerald-950/40",
  interview:  "border-violet-200  bg-violet-50  dark:border-violet-900  dark:bg-violet-950/40",
  offer:      "border-pink-200    bg-pink-50    dark:border-pink-900    dark:bg-pink-950/40",
  rejected:   "border-rose-200    bg-rose-50    dark:border-rose-900    dark:bg-rose-950/40",
  archived:   "border-edge        bg-surface-sunken",
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
  const accent = STATUS_ACCENT[status];

  return (
    <div className="flex min-w-[260px] flex-1 flex-col">
      <header className={`mb-3 rounded-lg border px-3 py-2.5 ${accent}`}>
        <h3 className="font-serif text-sm text-ink">
          {title}{" "}
          <span className="ml-1 rounded-full bg-surface-raised/70 px-2 py-0.5 text-[10px] font-semibold text-ink-soft dark:bg-surface-raised/40">
            {offers.length}
          </span>
        </h3>
        <p className="mt-0.5 text-[10px] text-ink-muted">{hint}</p>
      </header>

      <div
        ref={setNodeRef}
        className={`flex flex-1 flex-col gap-2 rounded-lg border-2 border-dashed p-2 transition ${
          isOver
            ? isReceiving
              ? "border-emerald-400 bg-emerald-50/40 dark:bg-emerald-900/20"
              : "border-rose-400 bg-rose-50/40 dark:bg-rose-900/20"
            : "border-transparent"
        }`}
      >
        {offers.length === 0 ? (
          <p className="my-4 text-center text-xs text-ink-muted">Nada aqui ainda</p>
        ) : (
          offers.map((offer) => <KanbanCard key={offer.id} offer={offer} onClick={onCardClick} />)
        )}
      </div>
    </div>
  );
};
