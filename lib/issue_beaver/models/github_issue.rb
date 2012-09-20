require 'active_support/core_ext' # Needed for delegate
require 'octokit'
require 'time'

module IssueBeaver
  module Models
    class GithubIssue
      def self.use_repository(repository)
        @repository = repository
        class << self
          delegate :all, :update, :create, to: :@repository
        end
      end


      include Shared::AttributesModel
      ATTRIBUTES = [:number, :state, :title, :body, :file, :begin_line, :created_at]      

      def closed?() state == "closed" end

      def open?() state == "open" end

      def new?() !number end

      def persisted?() !new? && !changed? end


      def initialize(attrs = {})
        self.attributes = attrs
        ATTRIBUTES.each do |attr| @attributes[attr] ||= nil end
        self.created_at = Time.parse(created_at) if created_at.kind_of?(String)
      end

      def update_attributes_with_limit(attrs)
        update_attributes_without_limit(attrs.only(:title))
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
      def initialize(repo, login = nil, password = nil)
        @repo = repo
        if login && password
          @client = Octokit::Client.new(login: login, password: password)
        else
          @client = Octokit
        end
      end

      def all
        @issues ||= @client.list_issues(@repo)
        Shared::ModelCollection.new(GithubIssue, @issues.map{|attrs| new_issue(attrs.dup)})
      end

      def update(number, attrs)
        sync_cache(
          @client.update_issue(@repo, number, attrs.title, attrs.body, attrs.only(:state, :labels))
        )
      end

      def create(attrs)
        sync_cache(
          @client.create_issue(@repo, attrs.title, attrs.body, attrs.only(:state, :labels))
        )
      end

      private
      def new_issue(attributes)
        GithubIssue.new(attributes)
      end

      def sync_cache(new_attrs)
        idx = @issues.find_index{|issue| issue.number == new_attrs.number}
        if idx
          @issues[idx] = new_attrs
        else
          @issues << new_attrs
        end
        new_attrs
      end
    end
  end
end