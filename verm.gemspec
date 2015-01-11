# -*- encoding: utf-8 -*-
require File.expand_path('../lib/verm/version', __FILE__)

spec = Gem::Specification.new do |gem|
  gem.name         = 'verm-client'
  gem.version      = Verm::VERSION
  gem.license      = "MIT"
  gem.summary      = "Tiny Ruby HTTP client for the Verm immutable, WORM filestore."
  gem.description  = <<-EOF
Adds one-line methods for storing files in Verm and retrieving them again.
EOF
  gem.has_rdoc     = false
  gem.author       = "Will Bryant"
  gem.email        = "will.bryant@gmail.com"
  gem.homepage     = "http://github.com/willbryant/verm-client-ruby"

  gem.executables  = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files        = `git ls-files`.split("\n")
  gem.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_path = "lib"
end
