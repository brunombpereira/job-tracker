import { useScraperHealth } from "@/hooks/useScraperHealth";
import type { SourceHealth } from "@/api/scraperHealth";

const fmtDate = (iso: string | null) =>
  iso ? new Date(iso).toLocaleString() : "nunca";

function reason(s: SourceHealth): string {
  if (s.consecutive_failures > 0) {
    return `${s.consecutive_failures} execução(ões) seguida(s) com erro`;
  }
  if (s.consecutive_zero_finds > 0) {
    return `${s.consecutive_zero_finds} execução(ões) seguida(s) sem encontrar ofertas`;
  }
  return "estado degradado";
}

/**
 * Heads-up strip for scraper reliability. HTML scrapers break silently
 * when a site changes its markup, so this surfaces sources that have
 * started failing or stopped finding offers. Stays quiet (a single line)
 * when everything is healthy.
 */
export function ScraperHealth() {
  const { data } = useScraperHealth();
  if (!data) return null;

  const problems = data.filter(
    (s) => s.status === "down" || s.status === "degraded",
  );

  if (problems.length === 0) {
    return (
      <p className="flex items-center gap-2 text-xs text-ink-muted">
        <span className="h-2 w-2 rounded-full bg-emerald-500" />
        Todas as fontes operacionais
      </p>
    );
  }

  return (
    <section className="rounded-lg border border-amber-300 bg-amber-50 px-4 py-3 dark:border-amber-900 dark:bg-amber-950/40">
      <h3 className="text-xs font-semibold uppercase tracking-wide text-amber-800 dark:text-amber-200">
        Fontes com problemas
      </h3>
      <ul className="mt-2 space-y-1.5">
        {problems.map((s) => (
          <li
            key={s.key}
            className="flex flex-wrap items-center gap-x-2 gap-y-0.5 text-sm"
          >
            <span
              className={`h-2 w-2 shrink-0 rounded-full ${
                s.status === "down" ? "bg-rose-500" : "bg-amber-500"
              }`}
            />
            <strong className="text-ink">{s.display_name}</strong>
            <span className="text-ink-soft">— {reason(s)}</span>
            <span className="text-xs text-ink-muted">
              (última execução: {fmtDate(s.last_run_at)})
            </span>
          </li>
        ))}
      </ul>
    </section>
  );
}
