/**
 * Quick-link cards for the job platforms we can't bulk-scrape (Cloudflare
 * + ToS walls). Each card opens the platform's search results with a
 * pre-filled junior-Portugal query in a new tab — the user browses
 * naturally and pastes the URL of anything interesting into the URL
 * importer below.
 *
 * Source colors mirror the URL importer's KNOWN_HOSTS map on the
 * backend so a Source row created via import is visually consistent
 * with this card.
 */

interface Platform {
  key: string;
  name: string;
  color: string;
  /** Brief explanation of what's there and why it's manual-only. */
  note: string;
  /** URL with a default junior-PT search pre-loaded. */
  url: string;
}

const PLATFORMS: Platform[] = [
  {
    key:   "indeed",
    name:  "Indeed PT",
    color: "#2557a7",
    note:  "Cloudflare bloqueia scraping — abre, pesquisa, cola URL no Importar",
    url:   "https://pt.indeed.com/jobs?q=junior+developer&l=Portugal&fromage=7&sort=date",
  },
  {
    key:   "glassdoor",
    name:  "Glassdoor",
    color: "#0caa41",
    note:  "Bom para ver salários antes de negociar",
    url:   "https://www.glassdoor.pt/Job/portugal-junior-developer-jobs-SRCH_IL.0,8_IN195_KO9,25.htm",
  },
  {
    key:   "itjobs",
    name:  "IT Jobs PT",
    color: "#ee6c4d",
    note:  "Foco PT em tech, muitas júnior",
    url:   "https://www.itjobs.pt/empregos/programacao?categoria=engenharia-informatica",
  },
  {
    key:   "sapo",
    name:  "SAPO Emprego",
    color: "#3da5d9",
    note:  "Agregador PT, alguma cobertura tech",
    url:   "https://emprego.sapo.pt/oferta-emprego/Junior+Developer?l=Portugal",
  },
  {
    key:   "remoteok",
    name:  "RemoteOK",
    color: "#000000",
    note:  "100% remoto internacional",
    url:   "https://remoteok.com/remote-junior-developer-jobs",
  },
  {
    key:   "otta",
    name:  "Welcome to the Jungle",
    color: "#ffcd00",
    note:  "Startups tech UK/Europa",
    url:   "https://www.welcometothejungle.com/en/jobs?refinementList%5Boffices.country_code%5D%5B%5D=PT&query=junior%20developer",
  },
  {
    key:   "wellfound",
    name:  "Wellfound",
    color: "#1f1f1f",
    note:  "Startups internacionais; muitas dão remoto",
    url:   "https://wellfound.com/jobs#find/f!%7B%22jobTypes%22%3A%5B%22full_time%22%5D%2C%22roleNames%22%3A%5B%22developer%22%5D%2C%22locationNames%22%3A%5B%22Portugal%22%5D%7D",
  },
  {
    key:   "ycombinator",
    name:  "Y Combinator Jobs",
    color: "#ff6600",
    note:  "Startups YC, muitas com remote",
    url:   "https://www.workatastartup.com/jobs?role=eng&query=junior",
  },
];

export const ManualPlatforms = () => (
  <section>
    <div className="mb-3 flex items-baseline justify-between gap-2">
      <h3 className="text-xs font-semibold uppercase tracking-wide text-ink-muted">
        Procurar manualmente noutras plataformas
      </h3>
      <p className="hidden text-[11px] text-ink-muted sm:block">
        clica → procura → cola o URL no Importar URL
      </p>
    </div>

    <div
      className="grid gap-2"
      style={{
        gridTemplateColumns: `repeat(${Math.max(2, Math.ceil(PLATFORMS.length / 2))}, minmax(0, 1fr))`,
      }}
    >
      {PLATFORMS.map((p) => (
        <a
          key={p.key}
          href={p.url}
          target="_blank"
          rel="noopener noreferrer"
          className="group relative flex flex-col gap-1 rounded-xl border border-edge bg-surface-raised p-3 text-left transition hover:border-edge-strong hover:shadow-soft"
          title={p.note}
        >
          <div className="flex items-center gap-2">
            <span
              className="inline-block h-2.5 w-2.5 rounded-full"
              style={{ backgroundColor: p.color }}
              aria-hidden="true"
            />
            <span className="truncate font-medium text-ink">{p.name}</span>
            <svg viewBox="0 0 24 24" className="ml-auto h-3.5 w-3.5 text-ink-muted transition group-hover:text-accent" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M7 17 17 7M17 7H8M17 7v9" />
            </svg>
          </div>
          <p className="text-[11px] text-ink-muted">{p.note}</p>
        </a>
      ))}
    </div>
  </section>
);
