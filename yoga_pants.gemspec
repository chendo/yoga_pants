# -*- encoding: utf-8 -*-
require File.expand_path('../lib/yoga_pants/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jack Chen (chendo)"]
  gem.email         = ["yoga_pants@chen.do"]
  gem.description   = %q{A super lightweight interface to ElasticSearch's HTTP REST API}
  gem.summary       = <<-TEXT.strip
    A super lightweight interface to ElasticSearch's HTTP REST API.
  TEXT
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "yoga_pants"
  gem.require_paths = ["lib"]
  gem.version       = YogaPants::VERSION

  gem.add_runtime_dependency 'httpclient', '2.2.5'
  gem.add_runtime_dependency 'multi_json'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'vcr'

end
