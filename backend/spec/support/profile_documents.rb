# Helpers for specs that need uploaded CV / cover-letter documents
# (ProfileDocument rows), which replaced the on-disk storage/profile/
# fixtures.
module ProfileDocumentsHelper
  PT_TEMPLATE = <<~MD.freeze
    {{city}}, {{date}}

    Caro/a {{recipient_name}},

    Venho candidatar-me à posição de {{position_title}} na {{company}},
    encontrada através de {{platform}}.

    Disponibilidade: {{start_date}}.
  MD

  EN_TEMPLATE = <<~MD.freeze
    {{city}}, {{date}}

    Dear {{recipient_name}},

    I am applying for the {{position_title}} position at {{company}},
    found via {{platform}}.

    Available to start {{start_date}}.
  MD

  def seed_cover_letter_templates
    ProfileDocument.create!(kind: "template_pt", filename: "template_pt.md",
                            content_type: "text/markdown", data: PT_TEMPLATE)
    ProfileDocument.create!(kind: "template_en", filename: "template_en.md",
                            content_type: "text/markdown", data: EN_TEMPLATE)
  end

  def seed_cv(kind, filename: "cv.pdf", content_type: "application/pdf", data: "%PDF-1.4 test")
    ProfileDocument.create!(kind: kind, filename: filename,
                            content_type: content_type, data: data)
  end
end

RSpec.configure { |config| config.include ProfileDocumentsHelper }
