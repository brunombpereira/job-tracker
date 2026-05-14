module Api
  module V1
    # Serves the personal artefacts (CV, cover-letter templates, generated
    # cover letters) that live in backend/storage/profile/ but never go
    # to the public repo. The frontend hits these endpoints from the
    # OfferDetail modal so the user can download what they need for the
    # specific listing they're looking at.
    class ProfileController < ApplicationController
      # GET /api/v1/profile — the editable profile (personal details +
      # scoring keyword lists), consumed by the Settings page.
      def show
        render json: profile_json
      end

      # PATCH /api/v1/profile
      def update
        Profile.current.update!(profile_params)
        Scorers::ProfileMatcher.reset_cache!
        render json: profile_json
      end

      # GET /api/v1/profile/files
      # Catalog of what's available + the basic profile facts (used by
      # the UI to render buttons + previews).
      def files
        profile = Profile.current
        render json: {
          name:     profile.name,
          city:     profile.city,
          email:    profile.email,
          phone:    profile.phone,
          github:   profile.github,
          linkedin: profile.linkedin,
          cv:       cv_catalog,
          cover_letters: cover_letter_catalog
        }
      end

      # GET /api/v1/profile/cv?lang=pt|en&format=visual|ats
      # Streams the matching CV file from disk with a download disposition.
      def cv
        lang   = params.fetch(:lang,   "pt").to_s
        format = params.fetch(:format, "visual").to_s
        path = cv_path_for(lang, format)
        return head :not_found unless path&.exist?

        send_file path, type: mime_for(path), disposition: "attachment", filename: path.basename.to_s
      end

      # GET /api/v1/profile/cover_letter?offer_id=:id&lang=pt|en[&download=true]
      # Generates a per-offer cover letter from the template.
      def cover_letter
        offer = Offer.find(params.require(:offer_id))
        lang  = params.fetch(:lang, "pt").to_s

        text = Offers::CoverLetterGenerator.generate(offer: offer, lang: lang)

        if params[:download] == "true"
          filename = Offers::CoverLetterGenerator.new(offer: offer, lang: lang).filename
          send_data text, type: "text/markdown; charset=utf-8", disposition: "attachment", filename: filename
        else
          render json: { content: text, filename: Offers::CoverLetterGenerator.new(offer: offer, lang: lang).filename }
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Offer not found" }, status: :not_found
      rescue Offers::CoverLetterGenerator::MissingTemplate => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def profile_json
        Profile.current.as_json(only: Profile::DETAIL_FIELDS + Profile::KEYWORD_FIELDS)
      end

      def profile_params
        params.require(:profile).permit(
          *Profile::DETAIL_FIELDS,
          *Profile::KEYWORD_FIELDS.map { |field| { field => [] } }
        )
      end

      def profile_storage
        Rails.application.config.x.profile_storage
      end

      def cv_root
        profile_storage.join("cv")
      end

      def cv_path_for(lang, format)
        return nil unless %w[pt en].include?(lang)
        dir = cv_root.join(lang)
        return nil unless dir.exist?

        pattern = format == "ats" ? "*ATS*" : "*Visual*"
        dir.glob(pattern).first
      end

      def cv_catalog
        %w[pt en].each_with_object({}) do |lang, out|
          out[lang] = {
            visual: cv_path_for(lang, "visual")&.basename&.to_s,
            ats:    cv_path_for(lang, "ats")&.basename&.to_s
          }.compact
        end
      end

      def cover_letter_catalog
        %w[pt en].each_with_object({}) do |lang, out|
          path = profile_storage.join("cover_letters", "template_#{lang}.md")
          out[lang] = path.exist?
        end
      end

      def mime_for(path)
        case path.extname.downcase
        when ".pdf"  then "application/pdf"
        when ".docx" then "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        when ".html" then "text/html; charset=utf-8"
        else "application/octet-stream"
        end
      end
    end
  end
end
