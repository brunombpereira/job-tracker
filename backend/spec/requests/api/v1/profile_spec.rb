require "rails_helper"

RSpec.describe "Api::V1::Profile", type: :request do
  describe "GET /api/v1/profile" do
    it "returns the editable profile fields" do
      get "/api/v1/profile"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("name", "city", "email", "primary_keywords", "linkedin_keywords")
      expect(body["primary_keywords"]).to be_an(Array)
    end
  end

  describe "PATCH /api/v1/profile" do
    it "updates personal details and keyword lists" do
      patch "/api/v1/profile", params: {
        profile: {
          name: "Ada Lovelace",
          city: "Lisboa",
          primary_keywords: %w[elixir phoenix],
          linkedin_keywords: [ "junior elixir developer" ]
        }
      }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Ada Lovelace")
      expect(body["primary_keywords"]).to eq(%w[elixir phoenix])

      profile = Profile.current
      expect(profile.city).to eq("Lisboa")
      expect(profile.linkedin_keywords).to eq([ "junior elixir developer" ])
    end

    it "resets the ProfileMatcher cache so new keywords take effect" do
      expect(Scorers::ProfileMatcher).to receive(:reset_cache!)
      patch "/api/v1/profile", params: { profile: { city: "Porto" } }
    end
  end

  describe "GET /api/v1/profile/files" do
    it "returns the profile catalog with CV + cover-letter availability flags" do
      get "/api/v1/profile/files"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body).to include("name", "city", "email", "github", "linkedin", "cv", "cover_letters")
      expect(body["cv"]).to have_key("pt")
      expect(body["cv"]).to have_key("en")
      expect(body["cover_letters"]["pt"]).to be(true).or be(false)
    end
  end

  describe "GET /api/v1/profile/cv" do
    it "serves the PT Visual CV as a PDF attachment" do
      get "/api/v1/profile/cv", params: { lang: "pt", format: "visual" }
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to start_with("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("CV_Bruno_Borlido_PT_Visual.pdf")
    end

    it "404s for an unknown format combination" do
      get "/api/v1/profile/cv", params: { lang: "xx", format: "visual" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/profile/cover_letter" do
    let!(:offer) do
      Offer.create!(title: "Backend Developer", company: "Acme", url: "https://ex.com/1")
    end

    it "returns the filled cover letter as JSON by default" do
      get "/api/v1/profile/cover_letter", params: { offer_id: offer.id, lang: "pt" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["content"]).to include("Acme", "Backend Developer", "Aveiro")
      expect(body["filename"]).to match(/Cover_Letter_acme_PT\.md/)
    end

    it "streams a markdown file when download=true" do
      get "/api/v1/profile/cover_letter",
          params: { offer_id: offer.id, lang: "en", download: "true" }
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to start_with("text/markdown")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.body).to include("Dear", "Acme", "Backend Developer")
    end

    it "404s for an unknown offer" do
      get "/api/v1/profile/cover_letter", params: { offer_id: 999_999, lang: "pt" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
