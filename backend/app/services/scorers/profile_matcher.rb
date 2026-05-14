module Scorers
  # Assigns an integer 1–5 match_score to an Offer based on how well it
  # aligns with the user's Profile. Used by Scrapers::BaseClient when a
  # scraped offer arrives without a score.
  #
  # The scoring rules are deliberately simple — tune the keyword lists in
  # the Settings page before touching the formula:
  #   base 3 (neutral)
  #   +1 per primary-stack hit (capped +2)
  #   +1 if title carries a junior signal (positive_title)
  #   +1 if location/modality has a positive geo/remote signal
  #   -1 if no primary hit AND offer.stack/description carry no signal
  #   -1 if title carries a "mid-level" / X+ years signal
  # Result clamped to [1, 5].
  class ProfileMatcher
    class << self
      def score(attrs)
        new(attrs).score
      end

      # Drops the memoized keyword config — call after the profile is
      # edited so the next score reflects the change.
      def reset_cache!
        @cached_config = nil
      end

      def config
        @cached_config ||= Profile.current.matcher_config
      end
    end

    def initialize(attrs)
      @attrs = attrs.is_a?(Hash) ? attrs : attrs.to_h
      @config = self.class.config
    end

    def score
      s = 3
      s += [ primary_hits, 2 ].min
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
      blob = [ @attrs[:location], @attrs[:modality] ].compact.join(" ").downcase
      list("location_bonus").any? { |kw| blob.include?(kw.to_s.downcase) }
    end

    # No primary OR secondary OR experimental match anywhere = a generic
    # offer that probably doesn't fit the profile.
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
      @text_blob ||= [ @attrs[:title], @attrs[:description] ].compact.join(" ").downcase
    end

    def list(key)
      Array(@config[key])
    end
  end
end
