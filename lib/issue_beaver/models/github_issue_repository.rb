require 'octokit'
require 'hashie'
require 'enumerable/lazy'

module IssueBeaver
  module Models
    class GithubIssueRepository

      def initialize(repo, login = nil, password = nil, default_attributes = {})
        @repo = repo
        if login && password
          @client = Octokit::Client.new(login: login, password: password)
        else
          @client = Octokit
        end
        @default_attributes = Hashie::Mash.new(default_attributes)
      end

      attr_reader :default_attributes


      def all
        @fetched_issues ||=
          Enumerator.new do |y|
            @client.list_issues(@repo).each do |i|
              y << i
            end
          end.memoizing.lazy
        @local_issues ||= []
        @issues ||= @fetched_issues.merge_right(@local_issues, :number).lazy
      end


      def first
        all.at(0)
      end


      def update(number, attrs)
        sync_cache do
          @client.update_issue(@repo, number, attrs.title, attrs.body, attrs.only(:state, :labels, :assignee))
        end
      end


      def create(attrs)
        sync_cache do
          @client.create_issue(@repo, attrs.title, attrs.body, attrs.only(:state, :labels, :assignee))
        end
      end


      private

      def sync_cache
        new_attrs = begin
          yield
        rescue Octokit::UnprocessableEntity => each
          puts "Failed to save issue (Check if there are invalid assignees or labels)"
          return nil
        end
        @local_issues << new_attrs
        new_attrs
      end

    end
  end
end