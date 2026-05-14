require "rails_helper"

RSpec.describe ProfileDocument, type: :model do
  describe "validations" do
    subject do
      described_class.new(kind: "cv_pt_visual", filename: "cv.pdf",
                          content_type: "application/pdf", data: "bytes")
    end

    it { is_expected.to be_valid }
    it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }
    it { is_expected.to validate_presence_of(:filename) }
    it { is_expected.to validate_presence_of(:content_type) }

    it "rejects a duplicate kind" do
      described_class.create!(kind: "cv_pt_visual", filename: "a.pdf",
                              content_type: "application/pdf", data: "x")
      dup = described_class.new(kind: "cv_pt_visual", filename: "b.pdf",
                                content_type: "application/pdf", data: "y")
      expect(dup).not_to be_valid
    end
  end

  describe ".for_kind" do
    it "finds the document for a kind slot" do
      doc = described_class.create!(kind: "template_pt", filename: "t.md",
                                    content_type: "text/markdown", data: "hi")
      expect(described_class.for_kind("template_pt")).to eq(doc)
      expect(described_class.for_kind("template_en")).to be_nil
    end
  end
end
