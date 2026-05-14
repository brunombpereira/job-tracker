# The SSRF guard in Offers::UrlImporter resolves hostnames to verify they
# don't point at an internal address. Real DNS would make the suite depend
# on network access it deliberately blocks (see WebMock.disable_net_connect!
# in rails_helper) and would fail for the fake hostnames used by
# stubbed-HTTP importer specs. So resolution is stubbed:
#
#   - IP literals and "localhost" resolve realistically, so the SSRF guard
#     specs still exercise the loopback / private / link-local code paths.
#   - every other hostname resolves to a fixed TEST-NET-3 address, which is
#     public as far as the guard is concerned — end-to-end importer specs
#     with WebMock-stubbed HTTP then pass without touching the network.
#
# Specs that need different resolution behaviour can re-stub Resolv.
RSpec.configure do |config|
  config.before do
    allow(Resolv).to receive(:getaddresses).and_wrap_original do |_original, host|
      if host == "localhost"
        [ "127.0.0.1" ]
      elsif host.match?(/\A\d+\.\d+\.\d+\.\d+\z/) || host.include?(":")
        [ host ]
      else
        [ "203.0.113.10" ] # TEST-NET-3 — a stand-in public address
      end
    end
  end
end
