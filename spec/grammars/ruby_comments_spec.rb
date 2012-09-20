require_relative '../spec_helper'

describe IssueBeaver::Grammars::RubyCommentsParser do
  
  let(:ruby_code) { File.read('./spec/fixtures/ruby.rb') }
  subject { IssueBeaver::Grammars::RubyCommentsParser.new.parse(ruby_code) }

  it "should find the one comment" do
    subject.comments.length.should == 1
  end

  it "should have correct properties" do
    comment = subject.comments[0]
    comment['begin_line'].should == 2
    comment['title'].should == "This line should be found in the tests"
  end

end