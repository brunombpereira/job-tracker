require "rails_helper"

RSpec.describe "DELETE /api/v1/offers/destroy_all", type: :request do
  it "archives every active offer by default — URLs preserved for dedup" do
    Offer.create!(title: "A", company: "Acme", url: "https://ex.com/1")
    Offer.create!(title: "B", company: "Globex", url: "https://ex.com/2")
    Offer.create!(title: "C", company: "Init", url: "https://ex.com/3", archived: true)

    delete "/api/v1/offers/destroy_all"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["archived"]).to eq(2)
    expect(body["deleted"]).to eq(0)

    # All rows still in DB so a re-scrape won't re-add them.
    expect(Offer.count).to eq(3)
    expect(Offer.active.count).to eq(0)
  end

  it "hard-deletes rows when hard=true (URLs gone — re-import possible)" do
    Offer.create!(title: "A", company: "Acme", url: "https://ex.com/1")
    Offer.create!(title: "B", company: "Globex", url: "https://ex.com/2")
    Offer.create!(title: "C", company: "Init", url: "https://ex.com/3", archived: true)

    delete "/api/v1/offers/destroy_all", params: { hard: "true" }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["deleted"]).to eq(2)
    expect(Offer.count).to eq(1) # only the archived one survives
  end

  it "hard-deletes including archived when hard=true and include_archived=true" do
    Offer.create!(title: "A", company: "Acme", url: "https://ex.com/1")
    Offer.create!(title: "B", company: "Globex", url: "https://ex.com/2", archived: true)

    delete "/api/v1/offers/destroy_all", params: { hard: "true", include_archived: "true" }

    expect(JSON.parse(response.body)["deleted"]).to eq(2)
    expect(Offer.count).to eq(0)
  end
end
