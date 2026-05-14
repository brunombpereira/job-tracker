namespace :offers do
  desc "Recompute match_score for auto-scored offers (run after editing the profile)"
  task rescore: :environment do
    count = Offers::Rescore.call
    puts "Rescored #{count} offer(s)."
  end
end
