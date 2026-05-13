import type { OfferStatus } from "@/types/offer";
import clsx from "clsx";

// Notion-style soft pills: low-saturation backgrounds with darker text in
// light mode, slightly desaturated dark backgrounds with lighter text in
// dark mode. Each row carries explicit dark: utilities so the badge stays
// readable across themes without depending on the global accent ramp.
const STATUS_CONFIG: Record<OfferStatus, { label: string; classes: string }> = {
  new: {
    label: "Novo",
    classes: "bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-200",
  },
  interested: {
    label: "Interessante",
    classes: "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-200",
  },
  applied: {
    label: "Candidatado",
    classes: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200",
  },
  interview: {
    label: "Entrevista",
    classes: "bg-violet-100 text-violet-800 dark:bg-violet-950 dark:text-violet-200",
  },
  offer: {
    label: "Oferta",
    classes: "bg-pink-100 text-pink-800 dark:bg-pink-950 dark:text-pink-200",
  },
  rejected: {
    label: "Rejeitado",
    classes: "bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-200",
  },
  archived: {
    label: "Arquivado",
    classes: "bg-surface-sunken text-ink-soft",
  },
};

interface Props {
  status: OfferStatus;
  className?: string;
}

export const StatusBadge = ({ status, className }: Props) => {
  const cfg = STATUS_CONFIG[status];
  return (
    <span
      className={clsx(
        "inline-block rounded-full px-2.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide",
        cfg.classes,
        className,
      )}
    >
      {cfg.label}
    </span>
  );
};
