require "resolv"
require "ipaddr"

module Offers
  # On-demand offer importer for sources we don't scrape in bulk (LinkedIn,
  # Indeed, Glassdoor, individual company career pages). The user pastes a
  # job-listing URL; we fetch it once with browser-like headers, extract
  # schema.org/JobPosting JSON-LD (which Google needs for indexing and most
  # major job boards therefore embed in SSR HTML), and create one Offer.
  #
  # Fall-back: if no JobPosting JSON-LD is present, the OpenGraph title +
  # description seeds a minimal Offer so the user can edit by hand.
  class UrlImporter
    class ImportError < StandardError; end

    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                 "AppleWebKit/537.36 (KHTML, like Gecko) " \
                 "Chrome/121.0.0.0 Safari/537.36"

    ALLOWED_PORTS = [ 80, 443 ].freeze

    # IP ranges that IPAddr's loopback?/private?/link_local? predicates do
    # not already cover but that still must never be reachable from a
    # server-side fetch.
    BLOCKED_RANGES = [
      IPAddr.new("0.0.0.0/8"),     # "this network"
      IPAddr.new("100.64.0.0/10"), # CGNAT — common inside cloud networks
      IPAddr.new("224.0.0.0/4")   # multicast
    ].freeze

    def self.import(url)
      new(url).import
    end

    def self.extract(url)
      new(url).extract
    end

    def initialize(url)
      @url = url.to_s.strip
    end

    def import
      raise ImportError, "URL em branco" if @url.empty?
      raise ImportError, "URL inválido" unless @url.match?(%r{\Ahttps?://})

      assert_safe_url!

      if (existing = Offer.find_by(url: @url))
        raise ImportError,
              "Já existe (Oferta ##{existing.id}: \"#{existing.title}\")"
      end

      html  = fetch_html
      attrs = extract_attrs(html)
      raise ImportError, "Não encontrei JobPosting nem OpenGraph nesta página" if attrs.blank?

      result = Offers::Ingest.call(
        attrs.merge(url: @url, status: "new"),
        source: source_for_host
      )
      return result.offer if result.created?

      raise ImportError, ingest_error_message(result)
    end

    # Validate + fetch + parse a job URL, returning the schema.org /
    # OpenGraph attrs hash — no dedup, no Offer creation. Used by the
    # on-demand description fetcher.
    def extract
      raise ImportError, "URL em branco" if @url.empty?
      raise ImportError, "URL inválido" unless @url.match?(%r{\Ahttps?://})

      assert_safe_url!
      attrs = extract_attrs(fetch_html)
      raise ImportError, "Não encontrei conteúdo extraível nesta página" if attrs.blank?

      attrs
    end

    private

    def ingest_error_message(result)
      case result.outcome
      when :skipped_duplicate
        "Esta oferta já existe"
      else
        result.errors.join(", ").presence || "Não foi possível importar a oferta"
      end
    end

    # Map well-known job-board hostnames onto pretty display names + brand
    # colors so the FiltersPanel chip and SourceCard render meaningfully
    # for offers that arrive via the importer. New entries are matched by
    # `host.include?(key)` so subdomains (pt.indeed.com, uk.linkedin.com)
    # all bucket into one Source row.
    KNOWN_HOSTS = {
      "linkedin.com"  => { name: "LinkedIn",  color: "#0a66c2" },
      "indeed.com"    => { name: "Indeed",    color: "#2557a7" },
      "glassdoor"     => { name: "Glassdoor", color: "#0caa41" },
      "wellfound.com" => { name: "Wellfound", color: "#000000" },
      "angel.co"      => { name: "Wellfound", color: "#000000" },
      "lever.co"      => { name: "Lever",     color: "#7a3ff7" },
      "greenhouse.io" => { name: "Greenhouse", color: "#19825e" },
      "workable.com"  => { name: "Workable",  color: "#5b3aeb" },
      "ashbyhq.com"   => { name: "Ashby",     color: "#1f1f1f" }
    }.freeze

    def source_for_host
      h = host
      meta = KNOWN_HOSTS.find { |key, _| h.include?(key) }&.last
      meta ||= { name: h.split(".").first.to_s.capitalize.presence || "Imported", color: "#94a3b8" }
      Source.find_or_create_by!(name: meta[:name]) { |s| s.color = meta[:color] }
    end

    # Guards against SSRF. The importer fetches a user-supplied URL
    # server-side, so without this check a crafted URL could reach the
    # cloud metadata endpoint (169.254.169.254) or internal services
    # (localhost, the Redis/Postgres private network on Render). We
    # reject non-standard ports and any host that resolves to a
    # private, loopback, or link-local address.
    #
    # Faraday.get does not follow redirects, so there is no redirect-hop
    # bypass today — but if a follow-redirects middleware is ever added,
    # this check must run again per hop.
    #
    # Caveat: DNS is resolved here and again by Faraday at connect time,
    # leaving a narrow DNS-rebinding window. Pinning the resolved IP
    # would close it but means bypassing Faraday's connection handling —
    # out of scope for now.
    def assert_safe_url!
      uri = URI.parse(@url)
      raise ImportError, "URL inválido" unless uri.is_a?(URI::HTTP) && uri.host.present?

      unless uri.port.nil? || ALLOWED_PORTS.include?(uri.port)
        raise ImportError, "Porta não permitida"
      end

      addresses = Resolv.getaddresses(uri.host)
      raise ImportError, "Não consegui resolver o domínio" if addresses.empty?

      addresses.each do |addr|
        ip = IPAddr.new(addr)
        if ip.loopback? || ip.private? || ip.link_local? ||
           BLOCKED_RANGES.any? { |range| range.include?(ip) }
          raise ImportError, "URL aponta para um endereço interno"
        end
      end
    rescue URI::InvalidURIError, IPAddr::Error
      raise ImportError, "URL inválido"
    end

    def fetch_html
      res = Faraday.get(@url) do |r|
        r.options.timeout = 20
        r.options.open_timeout = 5
        r.headers["User-Agent"]      = USER_AGENT
        r.headers["Accept"]          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        r.headers["Accept-Language"] = "en-US,en;q=0.9,pt;q=0.8"
      end
      raise ImportError, "HTTP #{res.status} de #{host}" unless res.success?
      res.body
    rescue Faraday::Error => e
      raise ImportError, "Falha de rede: #{e.message}"
    end

    def extract_attrs(html)
      doc = Nokogiri::HTML(html)
      job_attrs_from_jsonld(doc) || og_fallback(doc)
    end

    def job_attrs_from_jsonld(doc)
      doc.css('script[type="application/ld+json"]').each do |script|
        parsed = safe_json(script.text)
        candidates = parsed.is_a?(Array) ? parsed : [ parsed ]
        candidates.each do |obj|
          next unless obj.is_a?(Hash)
          next unless job_posting?(obj)
          return build_attrs(obj)
        end
      end
      nil
    end

    def job_posting?(obj)
      Array(obj["@type"] || obj["type"]).map(&:to_s).any? { |t| t.match?(/JobPosting/i) }
    end

    def build_attrs(obj)
      {
        title:       obj["title"].to_s.strip[0, 200].presence || "(sem título)",
        company:     (obj.dig("hiringOrganization", "name") || host).to_s.strip[0, 200],
        location:    extract_location(obj),
        modality:    extract_modality(obj),
        description: sanitize(obj["description"]),
        posted_date: parse_date(obj["datePosted"])
      }.compact
    end

    def extract_location(obj)
      Array(obj["jobLocation"]).map do |loc|
        addr = (loc.is_a?(Hash) ? loc["address"] : nil) || {}
        next if addr.empty?
        [ addr["addressLocality"], addr["addressRegion"], addr["addressCountry"] ]
          .compact_blank.join(", ")
      end.compact.uniq.first(2).join(" / ").presence
    end

    def extract_modality(obj)
      type = Array(obj["jobLocationType"]).map(&:to_s).join(" ").upcase
      return "remoto" if type.include?("TELECOMMUTE") || type.include?("REMOTE")
      "presencial"
    end

    def og_fallback(doc)
      title = meta(doc, 'meta[property="og:title"]')
      return nil if title.blank?
      {
        title:       title[0, 200],
        company:     host,
        description: meta(doc, 'meta[property="og:description"]') ||
                     meta(doc, 'meta[name="description"]')
      }.compact
    end

    def meta(doc, selector)
      doc.at_css(selector)&.[]("content")&.strip&.presence
    end

    def safe_json(s)
      JSON.parse(s)
    rescue JSON::ParserError
      nil
    end

    def parse_date(s)
      Date.parse(s.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def sanitize(html)
      Offers::DescriptionSanitizer.call(html)
    end

    def host
      URI.parse(@url).host.to_s.sub(/\Awww\./, "")
    rescue URI::InvalidURIError
      "unknown"
    end
  end
end
