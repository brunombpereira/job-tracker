import { useMemo, useState } from "react";
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  useSensor,
  useSensors,
  closestCorners,
} from "@dnd-kit/core";
import type { DragEndEvent, DragStartEvent } from "@dnd-kit/core";
import type { Offer, OfferStatus } from "@/types/offer";
import { STATUS_TRANSITIONS } from "@/types/offer";
import { KanbanColumn } from "./KanbanColumn";
import { KanbanCard } from "./KanbanCard";
import { useChangeStatus } from "@/hooks/useOffers";

interface Props {
  offers: Offer[];
  onCardClick?: (offer: Offer) => void;
}

const COLUMNS: { status: OfferStatus; title: string; hint: string }[] = [
  { status: "new",        title: "Novo",        hint: "Acabou de chegar" },
  { status: "interested", title: "Interessante", hint: "Vale a pena candidatar" },
  { status: "applied",    title: "Candidatado", hint: "À espera de resposta" },
  { status: "interview",  title: "Entrevista",  hint: "Em processo" },
  { status: "offer",      title: "Oferta",      hint: "Decisão" },
  { status: "rejected",   title: "Rejeitado",   hint: "Fim do funil" },
];

export const KanbanBoard = ({ offers, onCardClick }: Props) => {
  const statusMut = useChangeStatus();
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
  );

  // Local optimistic copy of offers — mutations reconcile via TanStack invalidation
  const [optimistic, setOptimistic] = useState<Record<number, OfferStatus>>({});
  const [draggingOffer, setDraggingOffer] = useState<Offer | null>(null);
  const [draggingFrom, setDraggingFrom] = useState<OfferStatus | null>(null);

  const byColumn = useMemo(() => {
    const buckets: Record<OfferStatus, Offer[]> = {
      new: [], interested: [], applied: [], interview: [], offer: [], rejected: [], archived: [],
    };
    for (const o of offers) {
      const s = (optimistic[o.id] ?? o.status) as OfferStatus;
      if (buckets[s]) buckets[s].push(o);
    }
    return buckets;
  }, [offers, optimistic]);

  const onDragStart = (e: DragStartEvent) => {
    const offer = e.active.data.current?.offer as Offer | undefined;
    if (offer) {
      setDraggingOffer(offer);
      setDraggingFrom((optimistic[offer.id] ?? offer.status) as OfferStatus);
    }
  };

  const onDragEnd = (e: DragEndEvent) => {
    setDraggingOffer(null);
    setDraggingFrom(null);
    if (!e.over) return;

    const offer = e.active.data.current?.offer as Offer | undefined;
    const target = String(e.over.id) as OfferStatus;
    if (!offer) return;

    const current = (optimistic[offer.id] ?? offer.status) as OfferStatus;
    if (current === target) return;

    const allowed = STATUS_TRANSITIONS[current] ?? [];
    if (!allowed.includes(target)) {
      // Visual rejection — flash by not applying the optimistic update
      console.warn(`Invalid transition: ${current} → ${target}`);
      return;
    }

    // Optimistic update
    setOptimistic((prev) => ({ ...prev, [offer.id]: target }));

    statusMut.mutate(
      { id: offer.id, status: target },
      {
        onError: () => {
          setOptimistic((prev) => {
            const { [offer.id]: _drop, ...rest } = prev;
            return rest;
          });
        },
        onSuccess: () => {
          // Clear the optimistic state once the query refetch lands
          setOptimistic((prev) => {
            const { [offer.id]: _drop, ...rest } = prev;
            return rest;
          });
        },
      },
    );
  };

  const allowedDrop = draggingFrom ? STATUS_TRANSITIONS[draggingFrom] ?? [] : [];

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCorners}
      onDragStart={onDragStart}
      onDragEnd={onDragEnd}
    >
      <div className="flex gap-4 overflow-x-auto pb-4 px-0.5">
        {COLUMNS.map((col) => {
          const isReceiving =
            draggingFrom !== null &&
            draggingFrom !== col.status &&
            allowedDrop.includes(col.status);

          return (
            <KanbanColumn
              key={col.status}
              status={col.status}
              title={col.title}
              hint={col.hint}
              offers={byColumn[col.status]}
              onCardClick={onCardClick}
              isReceiving={isReceiving}
            />
          );
        })}
      </div>

      <DragOverlay>{draggingOffer && <KanbanCard offer={draggingOffer} />}</DragOverlay>
    </DndContext>
  );
};
