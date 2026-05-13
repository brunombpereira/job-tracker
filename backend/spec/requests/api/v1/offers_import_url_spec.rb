require "rails_helper"

RSpec.describe "POST /api/v1/offers/import_url", type: :request do
  let(:url) { "https://www.indeed.com/viewjob?jk=abcd1234" }

  let(:jsonld_html) do
    body = {
      "@context"     => "https://schema.org/",
      "@type"        => "JobPosting",
      "title"        => "DevOps Engineer",
      "hiringOrganization" => { "name" => "Globex" },
      "description"  => "Build pipelines.",
      "datePosted"   => "2026-05-10",
      "jobLocationType" => "TELECOMMUTE"
    }.to_json
    "<html><script type='application/ld+json'>#{body}</script></html>"
  end

  it "returns 201 with the created Offer for a valid JobPosting page" do
    stub_request(:get, url).to_return(status: 200, body: jsonld_html)

    expect {
      post "/api/v1/offers/import_url", params: { url: url }, as: :json
    }.to change(Offer, :count).by(1)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["title"]).to eq("DevOps Engineer")
    expect(body["company"]).to eq("Globex")
    expect(body["url"]).to eq(url)
  end

  it "returns 422 with a clear error when the page has no metadata" do
    stub_request(:get, url).to_return(status: 200, body: "<html></html>")
    post "/api/v1/offers/import_url", params: { url: url }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to match(/Não encontrei/)
  end

  it "returns 422 when the upstream URL replies non-2xx" do
    stub_request(:get, url).to_return(status: 503)
    post "/api/v1/offers/import_url", params: { url: url }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to match(/HTTP 503/)
  end
end
