$LOAD_PATH.unshift File.expand_path('lib')

require 'bundler'
Bundler.setup

require 'issue_beaver/shared'
require 'issue_beaver/grammars'
require 'issue_beaver/models'
require 'issue_beaver/runner'

class Enumerator
  class Lazy
    def lazy
      puts "Called lazy one time to much"
      super
    end
  end
end
