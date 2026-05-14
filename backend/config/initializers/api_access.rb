# The API is gated by a shared-secret token (see
# ApplicationController#authenticate_request!). The gate is intentionally
# off when API_ACCESS_TOKEN is unset — convenient for local dev and the
# test suite — but a production deploy without it serves every endpoint,
# including the personal CV/profile data, to the public internet. Shout
# about it at boot so a misconfigured deploy is obvious in the logs.
if Rails.env.production? && ENV["API_ACCESS_TOKEN"].blank?
  Rails.logger.warn(
    "[security] API_ACCESS_TOKEN is not set — the API is publicly accessible. " \
    "Set it to require a shared-secret token on every request."
  )
end
