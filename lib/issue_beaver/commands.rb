require 'yaml'
require 'time-lord'

module IssueBeaver
  class CLI
    def initialize(*args)
      config_file = ".issuebeaver.yml"
      @config = default_config

      if File.readable?(config_file)
        @config.merge!(YAML.load(File.read(config_file)))
      end

      @command = args[0]
      setup_repos
    end

    def run
      runner = CommandRunner.new(@config)
      if runner.respond_to?(@command)
        runner.send(@command)
      else
        puts "#{@command}: Command not found"
      end
    end

    private
      def setup_repos
        Models::TodoComment.use_repository(Models::TodoCommentRepository.new(
          @config['dirs'],
          @config['files']))
        Models::GithubIssue.use_repository(Models::GithubIssueRepository.new(
          @config['github']['repo'],
          @config['github']['login'],
          @config['github']['password'],
          {:labels => @config['github']['labels']})) 
      end

      def default_config
        {
          'dirs' => [],
          'files' => '**/**.rb',
          'github' => {
            'repo' => '',
            'labels' => ['todo']
          }
        }
      end
    
    class CommandRunner
      def initialize(args)
        @args = args
      end

      def list
        issues = Models::Merger.new.merged_issues

        if todos.any?
          puts _list_todos(todos)
        else
          puts "No todos"
        end
      end

      def status
        issues = Models::Merger.new.changed
        if issues.empty?
          puts "Nothing new"
        else
          puts _list_status(issues)
        end
      end

      def diff
        issues = Models::Merger.new.changed
        if issues.empty?
          puts "Nothing new"
        else
          puts _list_diff(issues)
        end
      end

      def commit
        issues = Models::Merger.new.changed
        issues.each do |issue|
          issue.save
        end
      end

      private


      def max_length(list, attr)
        list.map(&attr).max{ |a,b| a.to_s.length <=> b.to_s.length}.to_s.length
      end

      def format_status(todos, todo)
        mod = sprintf "%#{max_length(todos, :modifier)}s   ", todo.modifier
        file = sprintf "%-#{max_length(todos, :file)}s", todo.file
        begin_line = sprintf "%-#{max_length(todos, :begin_line)}s  ", todo.begin_line
        title = sprintf "%-#{max_length(todos, :title) + 8}s", %Q{"#{todo.title}"}
        "#      #{mod}#{title} #{file}:#{begin_line}"
      end


      def format_diff(todos, todo)
        mod = sprintf "%#{max_length(todos, :modifier)}s   ", todo.modifier
        file = sprintf "%-#{max_length(todos, :file)}s", todo.file
        begin_line = sprintf "%-#{max_length(todos, :begin_line)}s  ", todo.begin_line
        title = sprintf "%-#{max_length(todos, :title) + 8}s", %Q{"#{todo.title}"}
        updated_at = "(#{todo.updated_at.ago_in_words})  "
        attrs = sprintf "%-#{max_length(todos, :changed_attributes_for_update)}s", todo.changed_attributes_for_update
        "#      #{mod}#{title} at #{file}:#{begin_line}#{updated_at}#{attrs}"
      end

      def _list_diff(todos)
        todos.map { |todo|
          format_diff(todos, todo)
        }.join("\n")
      end

      def _list_status(todos)
        todos.map {|todo|
          format_status(todos, todo)
          }.join("\n")
        end

      def _list_todos(todos, all_todos = todos)
        todos.map { |todo| format_line(all_todos, todo) }.join("\n")
      end

      def _list_todos_with_changes(todos, all_todos = todos)

        todos.map { |todo|
          head = format_line(all_todos, todo)
          lines = todo.changes.only(:title).map{|attr, change|
            "#{attr}: #{change[0]} => #{change[1]}"
          }
          [["#{head}"] + lines ].join("\n     ")
        }.join("\n")
      end
    end
  end
end