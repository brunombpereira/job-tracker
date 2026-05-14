require "rails_helper"

RSpec.describe "Api::V1 shared-secret auth", type: :request do
  context "when API_ACCESS_TOKEN is unset (gate disabled)" do
    it "reports auth is not required" do
      get "/api/v1/auth"
      body = JSON.parse(response.body)
      expect(body).to eq("required" => false, "authenticated" => true)
    end

    it "lets protected endpoints through without a token" do
      get "/api/v1/offers"
      expect(response).to have_http_status(:ok)
    end
  end

  context "when API_ACCESS_TOKEN is set (gate enabled)" do
    let(:token) { "s3cret-token" }

    around do |example|
      ENV["API_ACCESS_TOKEN"] = token
      example.run
    ensure
      ENV.delete("API_ACCESS_TOKEN")
    end

    it "401s a protected endpoint with no token" do
      get "/api/v1/offers"
      expect(response).to have_http_status(:unauthorized)
    end

    it "401s a protected endpoint with the wrong token" do
      get "/api/v1/offers", headers: { "Authorization" => "Bearer nope" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "allows a protected endpoint with the correct token" do
      get "/api/v1/offers", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
    end

    it "reports locked state on /auth without a token" do
      get "/api/v1/auth"
      body = JSON.parse(response.body)
      expect(body).to eq("required" => true, "authenticated" => false)
    end

    it "reports authenticated on /auth with the correct token" do
      get "/api/v1/auth", headers: { "Authorization" => "Bearer #{token}" }
      body = JSON.parse(response.body)
      expect(body).to eq("required" => true, "authenticated" => true)
    end
  end
end
