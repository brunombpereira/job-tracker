require "rails_helper"

RSpec.describe "DELETE /api/v1/offers/destroy_all", type: :request do
  it "wipes only active offers by default and returns the count" do
    Offer.create!(title: "A", company: "Acme")
    Offer.create!(title: "B", company: "Globex")
    Offer.create!(title: "C", company: "Init", archived: true)

    delete "/api/v1/offers/destroy_all"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq("deleted" => 2)
    expect(Offer.count).to eq(1) # the archived one survives
    expect(Offer.first.archived).to be(true)
  end

  it "wipes archived offers too when include_archived=true" do
    Offer.create!(title: "A", company: "Acme")
    Offer.create!(title: "B", company: "Globex", archived: true)

    delete "/api/v1/offers/destroy_all", params: { include_archived: "true" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq("deleted" => 2)
    expect(Offer.count).to eq(0)
  end
end
