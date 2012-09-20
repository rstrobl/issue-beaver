require 'treetop'

Dir.glob('./lib/issue_beaver/grammars/*').each do |grammar|
  Treetop.load grammar
end
