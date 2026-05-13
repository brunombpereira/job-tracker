require "rails_helper"

RSpec.describe Scrapers::HnWhoshiringClient do
  let(:user_body) { { id: "whoishiring", submitted: [9001, 9000, 8999] }.to_json }

  let(:thread_item) do
    { id: 9001, title: "Ask HN: Who is hiring? (May 2026)", kids: [10001, 10002, 10003] }.to_json
  end

  let(:other_item) do
    { id: 9000, title: "Ask HN: Who wants to be hired? (May 2026)", kids: [] }.to_json
  end

  let(:c1) do
    {
      id: 10001, by: "alice", time: 1746_000_000,
      text: "Acme | Backend Engineer | Lisbon, REMOTE | Ruby/Rails<p>Apply at jobs@acme.com"
    }.to_json
  end

  let(:c2) do
    { id: 10002, deleted: true }.to_json
  end

  let(:c3) do
    {
      id: 10003, by: "bob", time: 1746_000_100,
      text: "Globex Corp | Frontend Engineer | NYC, ONSITE | React<p>Send a CV"
    }.to_json
  end

  before do
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/user/whoishiring.json")
      .to_return(status: 200, body: user_body, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/9001.json")
      .to_return(status: 200, body: thread_item, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/9000.json")
      .to_return(status: 200, body: other_item, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/10001.json")
      .to_return(status: 200, body: c1, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/10002.json")
      .to_return(status: 200, body: c2, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/10003.json")
      .to_return(status: 200, body: c3, headers: { "Content-Type" => "application/json" })
  end

  it "locates the latest Who is hiring thread and parses non-deleted top-level comments" do
    result = nil
    expect { result = described_class.run }.to change(Offer, :count).by(2)
    expect(result).to include(found: 2, created: 2, skipped: 0)
  end

  it "splits company | title and infers remote/onsite modality" do
    described_class.run
    acme   = Offer.find_by(company: "Acme")
    globex = Offer.find_by(company: "Globex Corp")
    expect(acme.title).to eq("Backend Engineer")
    expect(acme.modality).to eq("remoto")
    expect(globex.title).to eq("Frontend Engineer")
    expect(globex.modality).to eq("presencial")
  end

  it "filters comments by keyword when supplied" do
    expect { described_class.run(keywords: "ruby") }.to change(Offer, :count).by(1)
    expect(Offer.last.company).to eq("Acme")
  end
end
