module Scorers
  # Assigns an integer 1–5 match_score to an Offer based on how well it
  # aligns with the profile defined in config/profile.yml. Used by
  # Scrapers::BaseClient when a scraped offer arrives without a score.
  #
  # The scoring rules are deliberately simple — adjust the YAML before
  # touching the formula:
  #   base 3 (neutral)
  #   +1 per primary-stack hit (capped +2)
  #   +1 if title carries a junior signal (positive_title)
  #   +1 if location/modality has a positive geo/remote signal
  #   -1 if no primary hit AND offer.stack/description carry no signal
  #   -1 if title carries a "mid-level" / X+ years signal
  # Result clamped to [1, 5].
  class ProfileMatcher
    CONFIG_PATH = Rails.root.join("config", "profile.yml")

    class << self
      def score(attrs)
        new(attrs).score
      end

      # Drops the cached YAML; tests that mutate the file (or want a
      # reload between cases) should call this in their before/after.
      def reset_cache!
        @cached_config = nil
      end

      def config
        return @cached_config if @cached_config && !Rails.env.development?
        @cached_config = load_config
      end

      private

      def load_config
        return {} unless CONFIG_PATH.exist?
        YAML.safe_load(CONFIG_PATH.read).to_h
      rescue StandardError => e
        Rails.logger.warn("[ProfileMatcher] config load failed: #{e.message}")
        {}
      end
    end

    def initialize(attrs)
      @attrs = attrs.is_a?(Hash) ? attrs : attrs.to_h
      @config = self.class.config
    end

    def score
      s = 3
      s += [primary_hits, 2].min
      s += 1 if positive_title?
      s += 1 if location_bonus?
      s -= 1 if no_signal?
      s -= 1 if negative_title?
      s.clamp(1, 5)
    end

    private

    def primary_hits
      list("primary").count { |kw| matches?(kw) }
    end

    def positive_title?
      list("positive_title").any? { |kw| title_includes?(kw) }
    end

    def negative_title?
      list("negative_title").any? { |kw| title_includes?(kw) }
    end

    def location_bonus?
      blob = [@attrs[:location], @attrs[:modality]].compact.join(" ").downcase
      list("location_bonus").any? { |kw| blob.include?(kw.to_s.downcase) }
    end

    # No primary OR secondary OR experimental match anywhere = a generic
    # offer that probably doesn't fit Bruno's profile.
    def no_signal?
      %w[primary secondary experimental].none? do |group|
        list(group).any? { |kw| matches?(kw) }
      end
    end

    # Does this keyword appear in the offer's stack array, title, or
    # description? Word-boundary on title/desc to avoid "ruby" matching
    # inside "rubyhost.com" etc.
    def matches?(keyword)
      kw = keyword.to_s.downcase
      stack_arr = Array(@attrs[:stack]).map { |s| s.to_s.downcase }
      return true if stack_arr.include?(kw)

      pattern =
        if kw.match?(/\W/)
          Regexp.new(Regexp.escape(kw))
        else
          Regexp.new("\\b#{Regexp.escape(kw)}\\b")
        end

      text_blob.match?(pattern)
    end

    def title_includes?(keyword)
      title = @attrs[:title].to_s.downcase
      kw = keyword.to_s.downcase
      if kw.match?(/\W/)
        title.include?(kw)
      else
        title.match?(Regexp.new("\\b#{Regexp.escape(kw)}\\b"))
      end
    end

    def text_blob
      @text_blob ||= [@attrs[:title], @attrs[:description]].compact.join(" ").downcase
    end

    def list(key)
      Array(@config[key])
    end
  end
end
