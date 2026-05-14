require "rails_helper"

RSpec.describe Offers::DescriptionSanitizer do
  describe ".call" do
    it "returns nil for blank input" do
      expect(described_class.call(nil)).to be_nil
      expect(described_class.call("")).to be_nil
    end

    it "keeps the safe formatting tags" do
      html = "<p>Build <strong>Rails</strong> apps</p><ul><li>API design</li></ul>"
      expect(described_class.call(html)).to eq(html)
    end

    it "decodes entity-encoded HTML so it renders instead of showing literal tags" do
      encoded = "&lt;strong&gt;Job Title&lt;/strong&gt;&lt;br&gt;Build &lt;em&gt;Rails&lt;/em&gt; apps."
      expect(described_class.call(encoded))
        .to eq("<strong>Job Title</strong><br>Build <em>Rails</em> apps.")
    end

    it "strips disallowed tags but keeps their text" do
      html = "<script>alert(1)</script><div>hello</div><strong>kept</strong>"
      result = described_class.call(html)
      expect(result).not_to include("<script>", "<div>")
      expect(result).to include("hello", "<strong>kept</strong>")
    end

    it "truncates to the max length" do
      expect(described_class.call("x" * 100, max: 10).length).to eq(10)
    end
  end
end
