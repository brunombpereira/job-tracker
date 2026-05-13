# Seeds para arranque rápido — espelha as seed offers do Cowork (job_offers.json)

puts "🌱 A semear sources e offers..."

sources_data = {
  "Indeed"     => "#003A9B",
  "LinkedIn"   => "#0A66C2",
  "IT Jobs"    => "#FF6B00",
  "Landing.jobs" => "#7950F2",
  "Direct"     => "#4a90b8",
  "Glassdoor"  => "#0CAA41",
  "IEFP"       => "#D72020"
}

sources_data.each do |name, color|
  Source.find_or_create_by!(name: name) { |s| s.color = color }
end

direct = Source.find_by!(name: "Direct")

seed_offers = [
  {
    title: "Junior Web Developer", company: "Jumpseller", location: "Porto",
    modality: "hibrido", stack: %w[Ruby Rails JavaScript PostgreSQL],
    url: "https://jumpseller.com/jobs/", match_score: 5, status: "interested",
    notes_text: "Plataforma de e-commerce. Stack Ruby on Rails alinhada com Wiremaze."
  },
  {
    title: "Junior Full-Stack Developer", company: "Nutrium", location: "Porto",
    modality: "hibrido", stack: %w[Ruby Rails React PostgreSQL],
    url: "https://nutrium.com/careers", match_score: 5, status: "interested",
    notes_text: "Software de nutrição. Stack 100% alinhada."
  },
  {
    title: "Junior Developer", company: "Mozantech", location: "Porto",
    modality: "hibrido", stack: %w[Ruby Rails Node React],
    url: "https://mozantech.com/careers", match_score: 5, status: "interested"
  },
  {
    title: "Fullstack Developer Junior", company: "FindHu", location: "Aveiro",
    modality: "hibrido", stack: [], url: "https://to.indeed.com/aadrs77xm4sc",
    match_score: 5, status: "new",
    notes_text: "Match ideal — Aveiro + junior + fullstack. Candidatar com prioridade."
  },
  {
    title: "Estágio Full-Stack Web Developer", company: "Cognipharma",
    location: "Remoto", modality: "remoto", stack: [],
    url: "https://to.indeed.com/aanjbyd9sw4r", match_score: 5, status: "new"
  },
  {
    title: "Junior Software Engineer", company: "Talkdesk",
    location: "Lisboa / Remoto Portugal", modality: "remoto",
    stack: %w[Node React Ruby Python], url: "https://www.talkdesk.com/careers/",
    match_score: 4, status: "interested"
  },
  {
    title: "Trainee Software Engineer", company: "Bosch",
    location: "Aveiro / Braga", modality: "hibrido",
    stack: %w[Java Python JavaScript], url: "https://www.bosch.pt/carreiras/",
    match_score: 4, status: "interested"
  }
]

seed_offers.each do |attrs|
  notes_text = attrs.delete(:notes_text)
  offer = Offer.find_or_initialize_by(url: attrs[:url])
  offer.assign_attributes(attrs.merge(source: direct, found_date: Date.current))
  offer.save!

  if notes_text && offer.notes.empty?
    offer.notes.create!(content: notes_text)
  end
end

puts "✅ #{Source.count} sources, #{Offer.count} offers, #{Note.count} notes"
