module Api
  module V1
    # The editable profile (personal details + scoring keywords) plus the
    # personal artefacts — CV PDFs and cover-letter templates — which are
    # uploaded through the app and stored as ProfileDocument rows.
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
      # Streams the matching uploaded CV with a download disposition.
      def cv
        lang   = params.fetch(:lang,   "pt").to_s
        format = params.fetch(:format, "visual").to_s
        doc = ProfileDocument.for_kind("cv_#{lang}_#{format}")
        return head :not_found unless doc

        send_data doc.data, type: doc.content_type, disposition: "attachment", filename: doc.filename
      end

      # GET /api/v1/profile/cover_letter?offer_id=:id&lang=pt|en[&download=true]
      # Generates a per-offer cover letter from the uploaded template.
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

      # POST /api/v1/profile/documents
      # multipart: kind=<ProfileDocument::KINDS>, file=<upload>
      # Creates or replaces the document in that slot.
      def upload
        kind = params.require(:kind).to_s
        file = params.require(:file)

        doc = ProfileDocument.find_or_initialize_by(kind: kind)
        doc.assign_attributes(
          filename:     file.original_filename,
          content_type: file.content_type.presence || "application/octet-stream",
          data:         file.read
        )
        doc.save!
        render json: { kind: doc.kind, filename: doc.filename }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # DELETE /api/v1/profile/documents/:kind
      def destroy_document
        ProfileDocument.for_kind(params[:kind])&.destroy
        head :no_content
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

      # { pt: { visual: filename, ats: filename }, en: {...} } — only the
      # slots that actually have an uploaded document.
      def cv_catalog
        %w[pt en].each_with_object({}) do |lang, out|
          out[lang] = %w[visual ats].each_with_object({}) do |format, slots|
            doc = ProfileDocument.for_kind("cv_#{lang}_#{format}")
            slots[format.to_sym] = doc.filename if doc
          end
        end
      end

      def cover_letter_catalog
        %w[pt en].each_with_object({}) do |lang, out|
          out[lang] = ProfileDocument.exists?(kind: "template_#{lang}")
        end
      end
    end
  end
end
