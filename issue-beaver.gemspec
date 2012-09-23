# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "issue-beaver"
  s.version     = "0.1.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephan Eckardt"]
  s.email       = ["mail@stephaneckardt.com"]
  s.homepage    = "https://github.com/eckardt/issue-beaver"
  s.summary     = %q{Issue Beaver creates Github Issues for TODO comments in your source code}
  s.description = s.summary

  s.add_dependency 'treetop'
  s.add_dependency 'octokit'
  s.add_dependency 'activemodel'
  s.add_dependency 'levenshtein'
  s.add_dependency 'hashie'
  s.add_dependency 'time-lord'
  s.add_dependency 'enumerable-lazy', '~> 0.0.1'
  s.add_dependency 'enumerator-memoizing'
  s.add_dependency 'grit'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'debugger'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
