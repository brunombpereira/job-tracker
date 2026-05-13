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
  new:        "border-blue-200    bg-blue-50",
  interested: "border-amber-200   bg-amber-50",
  applied:    "border-emerald-200 bg-emerald-50",
  interview:  "border-violet-200  bg-violet-50",
  offer:      "border-pink-200    bg-pink-50",
  rejected:   "border-rose-200    bg-rose-50",
  archived:   "border-slate-200   bg-slate-100",
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
      <header className={`mb-2 rounded-md border px-3 py-2 ${accent}`}>
        <h3 className="text-xs font-bold uppercase tracking-wide text-slate-800">
          {title}{" "}
          <span className="ml-1 rounded bg-white/70 px-1.5 py-0.5 text-[10px] font-semibold text-slate-700">
            {offers.length}
          </span>
        </h3>
        <p className="mt-0.5 text-[10px] text-slate-500">{hint}</p>
      </header>

      <div
        ref={setNodeRef}
        className={`flex flex-1 flex-col gap-2 rounded-md border-2 border-dashed p-2 transition ${
          isOver
            ? isReceiving
              ? "border-emerald-400 bg-emerald-50/40"
              : "border-rose-400 bg-rose-50/40"
            : "border-transparent"
        }`}
      >
        {offers.length === 0 ? (
          <p className="my-4 text-center text-xs text-slate-400">Nada aqui ainda</p>
        ) : (
          offers.map((offer) => <KanbanCard key={offer.id} offer={offer} onClick={onCardClick} />)
        )}
      </div>
    </div>
  );
};
