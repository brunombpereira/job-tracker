import type { OfferStatus } from "@/types/offer";
import clsx from "clsx";

const STATUS_CONFIG: Record<OfferStatus, { label: string; classes: string }> = {
  new:        { label: "Novo",         classes: "bg-blue-100   text-blue-800"   },
  interested: { label: "Interessante", classes: "bg-amber-100  text-amber-800"  },
  applied:    { label: "Candidatado",  classes: "bg-emerald-100 text-emerald-800" },
  interview:  { label: "Entrevista",   classes: "bg-violet-100 text-violet-800" },
  offer:      { label: "Oferta",       classes: "bg-pink-100   text-pink-800"   },
  rejected:   { label: "Rejeitado",    classes: "bg-rose-100   text-rose-800"   },
  archived:   { label: "Arquivado",    classes: "bg-slate-100  text-slate-700"  },
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
        "inline-block rounded-full px-2 py-0.5 text-xs font-semibold uppercase tracking-wide",
        cfg.classes,
        className,
      )}
    >
      {cfg.label}
    </span>
  );
};
