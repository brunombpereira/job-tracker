require "rails_helper"

RSpec.describe "Api::V1::Offers", type: :request do
  describe "GET /api/v1/offers" do
    let!(:offers) { create_list(:offer, 3) }

    it "returns paginated list" do
      get "/api/v1/offers"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(3)
      expect(response.headers["Total-Count"]).to eq("3")
    end

    it "respects per_page" do
      create_list(:offer, 10)
      get "/api/v1/offers", params: { per_page: 5 }

      body = JSON.parse(response.body)
      expect(body.size).to eq(5)
      expect(response.headers["Per-Page"]).to eq("5")
      expect(response.headers["Total-Count"].to_i).to eq(13) # 3 + 10
    end

    it "clamps per_page to the maximum page size" do
      get "/api/v1/offers", params: { per_page: 100_000 }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Per-Page"]).to eq(Api::V1::OffersController::MAX_PER_PAGE.to_s)
    end

    it "excludes archived offers from the default index" do
      create(:offer, :archived)
      get "/api/v1/offers"

      body = JSON.parse(response.body)
      expect(body.size).to eq(3)
    end

    it "includes archived offers when include_archived=true" do
      create(:offer, :archived)
      get "/api/v1/offers", params: { include_archived: "true" }

      body = JSON.parse(response.body)
      expect(body.size).to eq(4)
    end

    describe "filtering" do
      it "filters by single status" do
        create(:offer, :applied)
        get "/api/v1/offers", params: { status: "applied" }

        body = JSON.parse(response.body)
        expect(body.size).to eq(1)
        expect(body.first["status"]).to eq("applied")
      end

      it "filters by multiple statuses (CSV)" do
        create(:offer, :applied)
        create(:offer, status: "interview")
        get "/api/v1/offers", params: { status: "applied,interview" }

        body = JSON.parse(response.body)
        expect(body.size).to eq(2)
        expect(body.map { |o| o["status"] }).to match_array(%w[applied interview])
      end

      it "filters by modality" do
        create(:offer, modality: "remoto", title: "Remote-only role")
        get "/api/v1/offers", params: { modality: "remoto" }

        body = JSON.parse(response.body)
        modalities = body.map { |o| o["modality"] }
        expect(modalities).to all(eq("remoto"))
        expect(body.map { |o| o["title"] }).to include("Remote-only role")
      end

      it "filters by match_score_gte" do
        create(:offer, :high_match)
        get "/api/v1/offers", params: { match_score_gte: 5 }

        body = JSON.parse(response.body)
        expect(body.size).to be >= 1
        body.each { |o| expect(o["match_score"]).to be >= 5 }
      end

      it "filters by match_score range (gte + lte)" do
        create(:offer, match_score: 1)
        create(:offer, match_score: 3)
        create(:offer, match_score: 5)
        get "/api/v1/offers", params: { match_score_gte: 2, match_score_lte: 4 }

        body = JSON.parse(response.body)
        scores = body.map { |o| o["match_score"] }.compact
        expect(scores).to all(be_between(2, 4))
      end

      it "filters by location (ILIKE)" do
        create(:offer, location: "Porto, Portugal")
        create(:offer, location: "Lisboa, Portugal")
        get "/api/v1/offers", params: { location: "porto" }

        body = JSON.parse(response.body)
        locations = body.map { |o| o["location"] }
        expect(locations).to all(match(/porto/i))
      end

      it "searches by title, company, or description (ILIKE)" do
        create(:offer, title: "Ruby on Rails Developer", company: "Acme")
        create(:offer, title: "Frontend Engineer",       company: "RubyShop")
        create(:offer, title: "Backend Engineer",        company: "DevHouse", description: "We use Ruby on Rails")
        get "/api/v1/offers", params: { search: "ruby" }

        body = JSON.parse(response.body)
        expect(body.size).to be >= 3
      end
    end

    describe "sorting" do
      it "defaults to match_score:desc" do
        create(:offer, match_score: 1)
        create(:offer, match_score: 5)
        get "/api/v1/offers"

        body = JSON.parse(response.body)
        scores = body.map { |o| o["match_score"] }.compact
        expect(scores).to eq(scores.sort.reverse)
      end

      it "accepts sort=field:dir" do
        create(:offer, title: "Aardvark Co")
        create(:offer, title: "Zebra Co")
        get "/api/v1/offers", params: { sort: "title:asc" }

        body = JSON.parse(response.body)
        titles = body.map { |o| o["title"] }
        expect(titles.first).to start_with("A")
      end

      it "rejects unknown sort fields silently" do
        get "/api/v1/offers", params: { sort: "secret_field:desc" }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /api/v1/offers/:id" do
    it "returns offer with associations" do
      offer = create(:offer)
      get "/api/v1/offers/#{offer.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(offer.id)
      expect(body).to have_key("source")
      expect(body).to have_key("notes")
      expect(body).to have_key("status_changes")
    end

    it "returns 404 for unknown id" do
      get "/api/v1/offers/999999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/offers" do
    let(:valid_params) do
      { offer: { title: "Junior Dev", company: "Acme", location: "Porto", modality: "hibrido" } }
    end

    it "creates an offer" do
      expect {
        post "/api/v1/offers", params: valid_params
      }.to change(Offer, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns errors on invalid input" do
      post "/api/v1/offers", params: { offer: { title: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts stack as array" do
      post "/api/v1/offers", params: {
        offer: valid_params[:offer].merge(stack: %w[ruby rails])
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["stack"]).to match_array(%w[ruby rails])
    end
  end

  describe "PATCH /api/v1/offers/:id" do
    let(:offer) { create(:offer) }

    it "updates an offer" do
      patch "/api/v1/offers/#{offer.id}", params: { offer: { title: "Updated Title" } }

      expect(response).to have_http_status(:ok)
      expect(offer.reload.title).to eq("Updated Title")
    end
  end

  describe "DELETE /api/v1/offers/:id" do
    let!(:offer) { create(:offer) }

    it "soft-deletes (archives) the offer" do
      expect {
        delete "/api/v1/offers/#{offer.id}"
      }.to change { offer.reload.archived }.from(false).to(true)

      expect(response).to have_http_status(:no_content)
    end

    it "does not remove the row" do
      expect {
        delete "/api/v1/offers/#{offer.id}"
      }.not_to change(Offer, :count)
    end
  end

  describe "POST /api/v1/offers/import" do
    it "creates new offers and dedupes by url" do
      existing = create(:offer, url: "https://example.com/existing")

      body = {
        offers: [
          { title: "New 1", company: "Co A", url: "https://example.com/new-1" },
          { title: "New 2", company: "Co B", url: "https://example.com/new-2" },
          { title: "Dup",   company: "Co C", url: existing.url }, # duplicate
          { title: "Bad" } # missing required company
        ]
      }

      expect { post "/api/v1/offers/import", params: body, as: :json }
        .to change(Offer, :count).by(2)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["created"]).to eq(2)
      expect(json["skipped"]).to eq(1)
      expect(json["error_count"]).to eq(1)
    end
  end

  describe "GET /api/v1/offers/export.csv" do
    let!(:offer) { create(:offer, title: "Export Me", company: "Acme") }

    it "returns CSV with all active offers" do
      get "/api/v1/offers/export.csv"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to start_with("text/csv")
      expect(response.body).to include("Export Me")
      expect(response.body).to include("Acme")
      expect(response.body.lines.first).to include("title,company")
    end
  end

  describe "PATCH /api/v1/offers/:id/status" do
    let(:offer) { create(:offer, status: "new") }

    it "updates status and records a status_change" do
      expect {
        patch "/api/v1/offers/#{offer.id}/status", params: { status: "interested" }
      }.to change { offer.reload.status_changes.count }.by(1)

      expect(offer.reload.status).to eq("interested")
    end

    it "stores reason in the status_change" do
      patch "/api/v1/offers/#{offer.id}/status", params: { status: "interested", reason: "Looks fun" }

      change = offer.reload.status_changes.last
      expect(change.reason).to eq("Looks fun")
    end

    it "rejects invalid transitions with 422" do
      patch "/api/v1/offers/#{offer.id}/status", params: { status: "interview" }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to match(/cannot transition/)
    end

    it "archives the offer when transitioning to archived" do
      patch "/api/v1/offers/#{offer.id}/status", params: { status: "archived" }

      offer.reload
      expect(offer.status).to eq("archived")
      expect(offer.archived).to eq(true)
    end
  end
end
