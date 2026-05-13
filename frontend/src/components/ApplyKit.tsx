import { useState } from "react";
import { toast } from "sonner";
import {
  coverLetterDownloadUrl,
  cvDownloadUrl,
  getCoverLetterPreview,
} from "@/api/profile";
import { useProfileFiles } from "@/hooks/useProfile";

interface Props {
  offerId: number;
}

type Lang = "pt" | "en";

/**
 * Tiny panel on the OfferDetail modal that exposes the CV download +
 * the per-offer cover-letter generator. The user picks a language,
 * sees a preview filled with the offer's company/title/platform/etc.,
 * and downloads the markdown ready to be edited + saved as PDF.
 */
export const ApplyKit = ({ offerId }: Props) => {
  const { data: profile } = useProfileFiles();
  const [lang, setLang] = useState<Lang>("pt");
  const [preview, setPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const cvFile = profile?.cv?.[lang]?.visual;
  const hasCoverLetter = profile?.cover_letters?.[lang] === true;

  const onPreview = async () => {
    setLoading(true);
    try {
      const { content } = await getCoverLetterPreview(offerId, lang);
      setPreview(content);
    } catch {
      toast.error("Falha a gerar a carta. Verifica os logs do backend.");
    } finally {
      setLoading(false);
    }
  };

  const onCopy = async () => {
    if (!preview) return;
    try {
      await navigator.clipboard.writeText(preview);
      toast.success("Carta copiada para a clipboard");
    } catch {
      toast.error("Sem permissão para clipboard — usa Download em vez disso.");
    }
  };

  return (
    <section className="rounded-xl border border-edge bg-surface px-4 py-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h4 className="font-serif text-base text-ink">Kit de candidatura</h4>
          <p className="mt-0.5 text-xs text-ink-muted">
            CV + carta de apresentação adaptada a esta oferta
          </p>
        </div>

        <div className="inline-flex h-8 items-center rounded-lg border border-edge bg-surface-raised p-0.5 text-xs font-medium">
          {(["pt", "en"] as const).map((l) => (
            <button
              key={l}
              type="button"
              onClick={() => setLang(l)}
              className={`rounded-md px-3 py-1 transition ${
                lang === l ? "bg-surface-sunken text-ink shadow-soft" : "text-ink-muted hover:text-ink"
              }`}
              aria-pressed={lang === l}
            >
              {l.toUpperCase()}
            </button>
          ))}
        </div>
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        {cvFile ? (
          <a
            href={cvDownloadUrl(lang, "visual")}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-edge-strong bg-surface-raised px-3 text-sm font-medium text-ink-soft shadow-soft transition hover:border-accent hover:text-ink"
            title={cvFile}
          >
            <Icon name="download" />
            CV {lang.toUpperCase()} (PDF)
          </a>
        ) : (
          <span className="inline-flex h-9 items-center rounded-lg border border-dashed border-edge px-3 text-sm text-ink-muted">
            CV {lang.toUpperCase()} indisponível
          </span>
        )}

        {profile?.cv?.[lang]?.ats && (
          <a
            href={cvDownloadUrl(lang, "ats")}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-edge-strong bg-surface-raised px-3 text-sm font-medium text-ink-soft shadow-soft transition hover:border-accent hover:text-ink"
          >
            <Icon name="download" />
            CV {lang.toUpperCase()} (ATS .docx)
          </a>
        )}

        {hasCoverLetter && (
          <>
            <button
              type="button"
              onClick={onPreview}
              disabled={loading}
              className="inline-flex h-9 items-center gap-1.5 rounded-lg bg-accent px-4 text-sm font-medium text-white shadow-soft transition hover:bg-accent-deep disabled:opacity-60"
            >
              <Icon name="sparkles" />
              {loading ? "A gerar…" : preview ? "Atualizar carta" : "Gerar carta"}
            </button>
            <a
              href={coverLetterDownloadUrl(offerId, lang)}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-edge-strong bg-surface-raised px-3 text-sm font-medium text-ink-soft shadow-soft transition hover:border-accent hover:text-ink"
            >
              <Icon name="download" />
              .md
            </a>
          </>
        )}
      </div>

      {preview && (
        <div className="mt-4">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-semibold uppercase tracking-wide text-ink-muted">
              Preview ({lang.toUpperCase()})
            </p>
            <button
              type="button"
              onClick={onCopy}
              className="inline-flex items-center gap-1 rounded-md border border-edge-strong bg-surface-raised px-2 py-1 text-[10px] font-semibold uppercase tracking-wide text-ink-soft transition hover:border-accent hover:text-accent"
            >
              <Icon name="copy" small />
              Copiar
            </button>
          </div>
          <pre className="mt-2 max-h-72 overflow-auto whitespace-pre-wrap rounded-lg border border-edge bg-surface-raised p-3 text-xs leading-relaxed text-ink-soft">
            {preview}
          </pre>
          <p className="mt-2 text-[11px] text-ink-muted">
            Substitui os <code className="rounded bg-surface-sunken px-1">[…]</code> à
            mão antes de enviar (o gancho específico sobre a empresa e o parágrafo
            de motivação ficam contigo).
          </p>
        </div>
      )}
    </section>
  );
};

function Icon({ name, small = false }: { name: "download" | "sparkles" | "copy"; small?: boolean }) {
  const cls = small ? "h-3 w-3" : "h-4 w-4";
  if (name === "download") {
    return (
      <svg viewBox="0 0 24 24" className={cls} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3" />
      </svg>
    );
  }
  if (name === "sparkles") {
    return (
      <svg viewBox="0 0 24 24" className={cls} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1" />
      </svg>
    );
  }
  return (
    <svg viewBox="0 0 24 24" className={cls} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="9" y="9" width="13" height="13" rx="2" />
      <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
    </svg>
  );
}
