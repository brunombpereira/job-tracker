import { useDraggable } from "@dnd-kit/core";
import { CSS } from "@dnd-kit/utilities";
import type { Offer } from "@/types/offer";

interface Props {
  offer: Offer;
  onClick?: (offer: Offer) => void;
}

export const KanbanCard = ({ offer, onClick }: Props) => {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: offer.id,
    data: { offer },
  });

  const style = {
    transform: CSS.Translate.toString(transform),
    opacity: isDragging ? 0.4 : 1,
  };

  return (
    <article
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      onClick={() => onClick?.(offer)}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if ((e.key === "Enter" || e.key === " ") && !isDragging) {
          onClick?.(offer);
        }
      }}
      className="cursor-grab rounded-md border border-slate-200 bg-white p-3 shadow-sm transition hover:shadow active:cursor-grabbing"
    >
      <h4 className="truncate text-sm font-semibold text-brand-dark">{offer.title}</h4>
      <p className="truncate text-xs text-slate-600">
        {offer.company}
        {offer.location && <span className="text-slate-400"> · {offer.location}</span>}
      </p>
      {offer.stack.length > 0 && (
        <ul className="mt-2 flex flex-wrap gap-1">
          {offer.stack.slice(0, 3).map((tech) => (
            <li
              key={tech}
              className="rounded bg-indigo-50 px-1.5 py-0.5 text-[10px] text-indigo-700"
            >
              {tech}
            </li>
          ))}
          {offer.stack.length > 3 && (
            <li className="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] text-slate-500">
              +{offer.stack.length - 3}
            </li>
          )}
        </ul>
      )}
      <footer className="mt-2 flex items-center justify-between text-[10px] text-slate-500">
        {offer.match_score && (
          <span className="rounded bg-amber-50 px-1.5 py-0.5 text-amber-800">
            ★ {offer.match_score}/5
          </span>
        )}
        <span className="ml-auto">{offer.found_date}</span>
      </footer>
    </article>
  );
};
