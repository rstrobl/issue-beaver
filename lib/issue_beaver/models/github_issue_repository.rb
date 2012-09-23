require 'octokit'
require 'hashie'
require 'enumerable/lazy'
require 'password/password'

module IssueBeaver
  module Models
    class GithubIssueRepository

      def initialize(repo, login = nil, password = nil, default_attributes = {})
        @repo = repo
        @login = login
        @password = password
        @default_attributes = Hashie::Mash.new(default_attributes)
      end

      attr_reader :default_attributes, :repo


      def all
        @fetched_issues ||=
          Enumerator.new do |y|
            with_login{@client.list_issues(@repo)}.each do |i|
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
          with_login{@client.update_issue(@repo, number, attrs.title, attrs.body, attrs.only(:state, :labels, :assignee))}
        end
      end


      def create(attrs)
        sync_cache do
          with_login{@client.create_issue(@repo, attrs.title, attrs.body, attrs.only(:state, :labels, :assignee))}
        end
      end


      private

      def sync_cache
        new_attrs = begin
          yield
        rescue Octokit::UnprocessableEntity => e
          puts "Failed to save issue (Check if there are invalid assignees or labels)"
          puts e
          return nil
        end
        @local_issues << new_attrs
        new_attrs
      end


      def with_login(&block)
        if @login && @password
          @client ||= Octokit::Client.new(login: @login, password: @password)
        else
          @client ||= Octokit
        end
        block.call()
      rescue Octokit::Unauthorized,Octokit::NotFound => e
        @retries ||= 1
        @client = nil
        @login = nil if @retries > 1

        unless @login
          print "Github login: "
          @login = STDIN.gets.chomp
        end

        @password = Password.ask("Github password: ")
        puts

        if @retries < 3
          @retries += 1
          retry
        else
          raise e
        end
      end

    end
  end
end