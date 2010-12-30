# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "three20/version"

Gem::Specification.new do |s|
  s.name        = "three20"
  s.version     = Three20::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John Wang"]
  s.email       = ["john@johntwang.com"]
  s.homepage    = "http://github.com/jwang/three20"
  s.summary     = %q{Three20 gem}
  s.description = %q{Three20 gem for adding three20 to an iOS projects, updating three20 and adding extensions}

  s.rubyforge_project = "three20"
  s.add_dependency "thor"
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "ZenTest"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.post_install_message =<<eos
  ********************************************************************************
    Requires Git - http://git-scm.com

    Follow @three20 on Twitter for announcements, updates, and news.
    https://twitter.com/three20

    Join the mailing list!
    https://groups.google.com/group/three20

    Report issues on Github
    https://github.com/jwang/three20

  ********************************************************************************
eos
  
end
