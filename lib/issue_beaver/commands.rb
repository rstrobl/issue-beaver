require 'yaml'

module IssueBeaver
  class CLI
    def initialize(args)
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
          @config['github']['password'])) 
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

      def diff
        merger = Models::Merger.new
        added, changed = merger.added, merger.changed #, merger.deleted
        puts "New todos:", _list_todos(added) unless added.empty?
        puts "Changed todos:", _list_todos_with_changes(changed) unless changed.empty?
        # puts "Deleted todos:", _list_todos(deleted) unless deleted.empty?
        puts "Nothing new" if (added + changed).empty?
      end

      def save
        LocalTodoFinder.new(_pattern).commit
      end

      def debug
        require 'ruby-debug'
        debugger
        "Here is the debugger"
      end

      def list_remote
        # _list_todos RemoteTodoRepository.new(@args['github']['repo']).all
      end

      private

      def _pattern
        "{#{@args['dirs'].join(',')}}/#{@args['files']}"
      end

      def _list_todos(todos)
        todos.map { |todo|
          "#{todo.file}:#{todo.begin_line}: #{todo.title} (#{todo.created_at})"
        }.join("\n")
      end

      def _list_todos_with_changes(todos)
        todos.map { |todo|
          head = "#{todo.file}:#{todo.begin_line}: #{todo.title} (#{todo.created_at})"
          # debug; "hello"
          lines = todo.changes.only(:title).map{|attr, change|
            "#{attr}: #{change[0]} => #{change[1]}"
          }
          [["#{head}"] + lines ].join("\n     ")
        }.join("\n")
      end
    end
  end
end