ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

if ENV["ANDROID_REVIEW_APP"]
  require "dotenv"
  Dotenv.load(".env.android_review")
end
