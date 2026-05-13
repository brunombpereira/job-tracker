interface Props {
  html: string;
  /** Tech keywords highlighted inline in the rendered description. */
  stack?: string[];
  className?: string;
}

const escapeRegex = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/**
 * Wrap occurrences of every `keyword` in `html` with a <mark> tag so the
 * description visually surfaces the tech the offer requires. Works on
 * the post-sanitiser HTML because backend already restricts tags to a
 * safe allowlist (p/br/ul/li/strong/em/h3/h4/a/code).
 *
 * Avoids matching inside HTML tag names/attributes by skipping when the
 * surrounding context looks like markup — a deliberate best-effort
 * heuristic (no full DOM parse needed for this scale).
 */
function highlightTech(html: string, stack: string[]): string {
  if (!stack.length) return html;
  // Sort longest first so "Ruby on Rails" matches before "Ruby" alone.
  const sorted = [...stack].sort((a, b) => b.length - a.length);
  const pattern = sorted.map(escapeRegex).join("|");
  // Match the keyword only when it's a standalone word AND not already
  // inside an HTML tag. We do this with a negative lookahead on the rest
  // of the string up to the next `<` — cheap and good-enough.
  const re = new RegExp(`\\b(${pattern})\\b(?![^<]*>)`, "gi");
  return html.replace(re, "<mark>$1</mark>");
}

/**
 * Renders pre-sanitised description HTML with prose styling and inline
 * highlighting. Backend's BaseClient#safe_html allow-list keeps the input
 * safe; we still gate the dangerouslySetInnerHTML behind a typed prop.
 */
export function DescriptionView({ html, stack = [], className = "" }: Props) {
  const rendered = stack.length ? highlightTech(html, stack) : html;
  return (
    <div
      className={`offer-description text-sm leading-relaxed text-ink-soft ${className}`}
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{ __html: rendered }}
    />
  );
}
