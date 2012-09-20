require_relative '../spec_helper'

describe IssueBeaver::Grammars::RubyCommentsParser do
  
  context "ruby.rb" do
    let(:ruby_code) { File.read('./spec/fixtures/ruby.rb') }
    subject { IssueBeaver::Grammars::RubyCommentsParser.new.parse(ruby_code) }
    let(:comment) {subject.comments[0]}

    it "should find the one comment" do
      subject.comments.length.should == 1
    end

    it "should have correct properties" do
      comment['begin_line'].should == 2
      comment['title'].should == "This line should be found in the tests"
    end

    it "should find the comment body" do
      comment['body'].should == nil
    end
  end

  context "ruby2.rb" do
    let(:ruby_code) { File.read('./spec/fixtures/ruby2.rb') }
    subject { IssueBeaver::Grammars::RubyCommentsParser.new.parse(ruby_code) }
    let(:comments) {subject.comments}

    it "should find the number of comment" do
      comments.length.should == 3
    end

    it "should have correct properties" do
      comments[0]['begin_line'].should == 2
      comments[0]['title'].should == "This line should be found in the tests"
    end

    it "should find the comment body" do
      comments[0]['body'].should == "And this should be found\nas the body"
    end

    it "should have correct properties" do
      comments[1]['begin_line'].should == 8
      comments[1]['title'].should == "Second comment"
    end

    it "should find the comment body" do
      comments[1]['body'].should == nil
    end

    it "should find the title without assignee" do
      comments[2]['title'].should == "Change to 42"
    end

    it "should find the assignee" do
      comments[2]['assignee'].should == "foobar"
    end
  end

end