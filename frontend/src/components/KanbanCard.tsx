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
      className="cursor-grab rounded-lg border border-edge bg-surface-raised p-3 shadow-soft transition hover:shadow-raise active:cursor-grabbing"
    >
      <h4 className="truncate font-serif text-sm text-ink">{offer.title}</h4>
      <p className="mt-0.5 truncate text-xs text-ink-soft">
        <span className="font-medium">{offer.company}</span>
        {offer.location && <span className="text-ink-muted"> · {offer.location}</span>}
      </p>
      {offer.stack.length > 0 && (
        <ul className="mt-2 flex flex-wrap gap-1">
          {offer.stack.slice(0, 3).map((tech) => (
            <li
              key={tech}
              className="rounded-md bg-accent-ghost px-1.5 py-0.5 text-[10px] text-accent-deep dark:bg-accent-soft/30"
            >
              {tech}
            </li>
          ))}
          {offer.stack.length > 3 && (
            <li className="rounded-md bg-surface-sunken px-1.5 py-0.5 text-[10px] text-ink-muted">
              +{offer.stack.length - 3}
            </li>
          )}
        </ul>
      )}
      <footer className="mt-3 flex items-center justify-between text-[10px] text-ink-muted">
        {offer.match_score && (
          <span className="rounded-md bg-amber-50 px-1.5 py-0.5 text-amber-800 dark:bg-amber-950 dark:text-amber-200">
            ★ {offer.match_score}/5
          </span>
        )}
        <span className="ml-auto">{offer.found_date}</span>
      </footer>
    </article>
  );
};
