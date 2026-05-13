require "rails_helper"

RSpec.describe "Api::V1::Sources", type: :request do
  describe "GET /api/v1/sources" do
    it "returns sources sorted alphabetically with active offer counts" do
      remotive  = Source.create!(name: "Remotive", color: "#3da5d9")
      teamlyzer = Source.create!(name: "Teamlyzer", color: "#e07a5f")
      Source.create!(name: "Empty Source", color: "#000")

      Offer.create!(title: "X", company: "Acme", source_id: remotive.id)
      Offer.create!(title: "Y", company: "Globex", source_id: remotive.id)
      Offer.create!(title: "Z", company: "Init", source_id: teamlyzer.id, archived: true)

      get "/api/v1/sources"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      remotive_row  = body.find { |s| s["name"] == "Remotive" }
      teamlyzer_row = body.find { |s| s["name"] == "Teamlyzer" }
      empty_row     = body.find { |s| s["name"] == "Empty Source" }

      expect(remotive_row).to include("id", "name", "color", "count")
      expect(remotive_row["count"]).to eq(2)
      expect(teamlyzer_row["count"]).to eq(0) # archived offers don't count
      expect(empty_row["count"]).to eq(0)

      # Sorted alphabetically
      names = body.map { |s| s["name"] }
      expect(names).to eq(names.sort)
    end
  end
end
