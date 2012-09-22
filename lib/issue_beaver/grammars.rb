require 'treetop'

require 'issue_beaver/grammars/ruby_comments'
Treetop.load File.expand_path('../grammars/ruby_comments.treetop', __FILE__)