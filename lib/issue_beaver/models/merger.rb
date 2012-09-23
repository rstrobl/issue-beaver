require 'levenshtein'

module IssueBeaver
  module Models
    class Merger

      def initialize(issues, todos)
        @issues = issues
        @matcher = Matcher.new(@issues, todos)
      end


      def added
        @added ||= merged_issues.select(&:new?)
      end


      def modified
        @modified ||= merged_issues.select(&:must_update?)
      end


      def changed
        @changed ||= merged_issues.select{|e| e.must_update? || e.new? }
      end


      # TODO: Detect removed TODO comments and close Issue on Github
      # Can probably be done by looking up the git history of a file.

      def merged_issues
        @merged_issues ||=
        @matcher.matches.map do |todo, issue|
          if issue
            if todo.updated_at > issue.updated_at
              issue.update_attributes(todo.attributes)
            end
          else
            issue = todo
          end
          issue
        end
      end
    end


    class Matcher

      def initialize(issues, todos)
        @issue_matcher = IssueMatcher.new(issues)
        @todos = todos
      end


      def matches
        @matches ||=
          Enumerator.new do |yielder|
            @todos.each do |todo|
              match = @issue_matcher.find_and_check_off(todo)
              issue = match ? match.issue : nil
              yielder << [todo, issue]
            end
          end.memoizing.lazy
      end

    end

    class IssueMatcher

      def initialize(issues)
        @issues = issues
        @found_issues = []
      end


      # Won't match the same issue twice for two different todos
      def find_and_check_off(todo)
        find(todo).tap do |match|
          @found_issues.push match.issue if match
        end
      end


      def find(todo)
        best_match = all_matches(todo).sort_by(&:degree).first
        if best_match && best_match.sane?
          best_match
        else
          nil
        end
      end


      private

      def all_matches(todo)
        @issues.reject{|issue| @found_issues.include? issue}.
                map{|issue| Match.new(todo, issue) }
      end


      class Match

        TITLE_THRESHOLD = 0.4
        BODY_THRESHOLD = 0.9

        def initialize(todo, issue)
          @todo = todo
          @issue = issue
        end

        attr_reader :todo, :issue


        def sane?
          (title_degree < TITLE_THRESHOLD) ||
          ((body_degree < BODY_THRESHOLD) && (body_accuracy < 0.1))
        end


        def degree
          title_degree + (body_degree * 0.25)
        end


        def title_degree() levenshtein(@issue.title, @todo.title) end


        def body_degree() levenshtein(@issue.body, @todo.body) end


        def body_accuracy() 1.0/[@issue.body.to_s.length, @todo.body.to_s.length].min.to_f end


        private

        def levenshtein(a, b)
          Levenshtein.distance(a.to_s, b.to_s).to_f / [1, a.to_s.length, b.to_s.length].max
        end

      end

    end

  end
end