require 'active_support/core_ext' # Needed for delegate
require 'octokit'
require 'time'
require 'hashie'
require 'enumerable/lazy'

module IssueBeaver
  module Models
    class GithubIssue
      def self.use_repository(repository)
        @repository = repository

        class << self
          delegate :update, :create, :default_attributes, :first, to: :@repository
        end
      end

      def self.all
        Shared::ModelCollection.new(self, @repository.all.map{|attrs| new_from_github(attrs.dup)})
      end


      include Shared::AttributesModel
      ATTRIBUTES = [:number, :state, :title, :body, :file, :begin_line, :created_at, :updated_at, :labels, :assignee]      

      def closed?() state == "closed" end

      def open?() state == "open" end

      def new?() !number end

      def persisted?() !new? && !changed? end

      def changed_attributes_for_update
        Hashie::Mash.new(changed_attributes).only(:title, :body, :assignee)
      end

      def must_update?() changed_attributes_for_update.any? end

      def self.new_from_github(attrs)
        new(attrs).tap do |obj|
          obj.clean_attributes_from_github
        end
      end

      def self.new_from_todo(attrs)
        new(attrs).tap do |obj|
          obj.clean_attributes_from_todo
        end
      end

      def initialize(attrs = {})
        @attributes = Hashie::Mash.new(attrs)
        ATTRIBUTES.each do |attr| @attributes[attr] ||= nil end
      end

      def clean_attributes_from_github
        self.attributes.merge! self.class.default_attributes
        self.created_at = Time.parse(created_at) if created_at.kind_of?(String)
        self.updated_at = Time.parse(updated_at) if updated_at.kind_of?(String)
        self.assignee = assignee.login if assignee.respond_to?(:login)
        @changed_attributes = nil
      end

      def clean_attributes_from_todo
        basename = File.basename(self.file)
        self.title = "#{self.title} (#{basename}:#{self.begin_line})"
        @changed_attributes = nil
      end

      def update_attributes_with_limit(attrs)
        update_attributes_without_limit(attrs.only(:title, :body, :updated_at, :assignee))
      end
      alias_method_chain :update_attributes, :limit

      def save
        if new?
          @attributes = self.class.create(attributes)
        elsif changed?
          @attributes = self.class.update(number, attributes)
        end
        @changed_attributes.clear
        true
      end
    end




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