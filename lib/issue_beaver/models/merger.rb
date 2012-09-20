require 'levenshtein'

module IssueBeaver
  module Models
    class Merger
      def initialize(issues = GithubIssue.all)
        @issues = issues
        @matcher = Matcher.new(@issues)
      end

      def added
        merged_issues.select(&:new?)
      end

      def modified
        merged_issues.select(&:must_update?)
      end

      def changed
        added + modified
      end

      def merged_issues
        @merged_issues ||= update_issues
      end

      private

      def update_issues
        @matcher.matches.each do |todo, issue|
          if issue
            if todo.updated_at > issue.updated_at
              issue.update_attributes(todo.to_issue_attrs)
            else
            end
          else
            issue = @issues.new(todo.to_issue_attrs)
            @issues << issue
          end
        end
        @issues
      end
    end

    class Matcher
      def initialize(issues)
        @issue_matcher = IssueMatcher.new(issues)
      end

      def matches
        @matches ||= match!
      end

      def match!
        matches = {}
        todos.each do |todo|
          issue = @issue_matcher.delete(todo)
          matches[todo] ||= issue
        end
        matches
      end

      def todos
        @todos ||= TodoComment.all
      end
    end

    class IssueMatcher
      def initialize(issues)
        @issues = issues.dup
      end

      # Won't match the same issue twice for two different todos
      def delete(todo)
        find(todo).tap do |issue|
          @issues.delete(issue) unless issue.nil?
        end
      end

      def find(todo)
        best_match = all_matches(todo).sort_by(&:degree).first
        if best_match && best_match.sane?
          best_match.issue
        else
          nil
        end
      end

      private

      def all_matches(todo)
        @issues.map{|issue| Match.new(todo, issue) }
      end

      class Match
        TITLE_THRESHOLD = 0.1

        attr_reader :todo, :issue
        def initialize(todo, issue)
          @todo = todo
          @issue = issue
        end

        def sane?
          title_degree < TITLE_THRESHOLD
        end

        def degree
          title_degree
        end

        def title_degree
          Levenshtein.distance(@issue.title, @todo.title).to_f / [1, @issue.title.length, @todo.title.length].max
        end
      end
    end
  end
end