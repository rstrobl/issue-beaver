require 'yaml'
require 'time-lord'

module IssueBeaver
  class Runner

    COMMANDS = %w(find status diff commit help)

    def self.run(*args)
      command = args[0]
      runner = self.new
      command = args[0]
      command = "unknown" unless COMMANDS.include? command
      runner.send(command, *args)
    end


    def find(*args)
      config['dir'] = args[1] if args[1]

      if todo_comments.all.any?
        _list_status(todo_comments.all)
      else
        puts "Nothing found"
      end
    end


    def status(*args)
      config['dir'] = args[1] if args[1]
      issues = merger(github_issues.all, todo_comments.all).changed
      if issues.any?
        _list_status(issues)
      else
        puts "Nothing new"
      end
    end


    def diff(*args)
      config['dir'] = args[1] if args[1]
      issues = merger(github_issues.all, todo_comments.all).changed
      if issues.any?
        _list_diff(issues)
      else
        puts "Nothing new"
      end
    end


    def commit(*args)
      config['dir'] = args[1] if args[1]
      issues = merger(github_issues.all, todo_comments.all).changed
      issues.each do |issue|
        issue.save
      end
    end


    def help
      puts "Available commands: #{COMMANDS.join(", ")}"
    end


    private

    def unknown(command = "", *args, &block)
      puts "#{command}: Command not found"
      help
    end


    def max_length(list, attr, elem = nil)
      if elem
        elem.send(attr).to_s.length
      else
        list.map(&attr).max{ |a,b| a.to_s.length <=> b.to_s.length}.to_s.length
      end
    end


    def format_status(todos, todo)
      mod = sprintf "%#{max_length(todos, :modifier, todo)}s   ", todo.modifier
      file = sprintf "%#{max_length(todos, :file, todo)}s", todo.file
      begin_line = sprintf "%-#{max_length(todos, :begin_line, todo)}s  ", todo.begin_line
      title = sprintf "%-#{max_length(todos, :title, todo) + 8}s", todo.title
      "#      #{mod}#{title} #{file}:#{begin_line}"
    end


    def format_diff(todos, todo)
      mod = sprintf "%#{max_length(todos, :modifier, todo)}s   ", todo.modifier
      file = sprintf "%#{max_length(todos, :file, todo)}s", todo.file
      begin_line = sprintf "%-#{max_length(todos, :begin_line, todo)}s  ", todo.begin_line
      title = sprintf "%-#{max_length(todos, :title, todo) + 8}s", todo.title
      updated_at = "(#{todo.updated_at.ago_in_words})  "
      attrs = sprintf "%-#{max_length(todos, :changed_attributes_for_update, todo)}s", todo.changed_attributes_for_update
      "#      #{mod}#{title} at #{file}:#{begin_line}#{updated_at}#{attrs}"
    end


    def _list_diff(todos)
      todos.each do |todo|
        puts format_diff(todos, todo)
      end
    end


    def _list_status(todos)
      todos.each do |todo|
        puts format_status(todos, todo)
      end
    end


    def todo_comments(config = config)
      @todo_comments ||=
      Models::TodoComments.new(
        repo(config).root_dir,
        repo(config).files(config['dir'])
        )
    end


    def github_issues(config = config)
      Models::GithubIssue.use_repository(Models::GithubIssueRepository.new(
        repo(config).slug,
        config['github']['login'],
        config['github']['password'],
        {:labels => config['github']['labels']})) 
      Models::GithubIssue
    end


    def repo(config = config)
      @repo ||= Models::Git.new(config['dir'], config['github']['repo'])
    end


    def merger(a, b)
      @merger ||= Models::Merger.new(a, b)
    end


    def git_repo(config = config)
      repo = Grit::Repo.new(config['dir'])
    end


    def config
      @config ||=
      begin
        config_file = ".issuebeaver.yml"
        config = DEFAULT_CONFIG.dup

        if File.readable?(config_file)
          config.merge!(YAML.load(File.read(config_file)))
        end

        config
      end
    end


    DEFAULT_CONFIG =
      {
        'dir' => '.',
        'github' => {
          'repo' => 'remote.origin',
          'labels' => ['todo']
        }
      }

  end
end