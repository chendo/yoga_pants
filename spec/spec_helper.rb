require 'vcr'
require 'yoga_pants'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true if ENV['ALLOW_NO_CASSETTE']
  c.ignore_localhost = true if ENV['INTEGRATION']
end
