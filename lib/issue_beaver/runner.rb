require 'yaml'
require 'time-lord'

module IssueBeaver
  class Runner
    def self.run(*args)
      command = args[0]
      runner = self.new(*args)
      runner.send(command)
    end

    DEFAULT_CONFIG =
      {
        'dirs' => [],
        'files' => '**/**.rb',
        'github' => {
          'repo' => '',
          'labels' => ['todo']
        }
      }

    def initialize(config)
      config_file = ".issuebeaver.yml"
      @config = DEFAULT_CONFIG.dup

      if File.readable?(config_file)
        @config.merge!(YAML.load(File.read(config_file)))
      end
    end


    def find
      todos = todo_comments.all
      if todos.empty?
        puts "Nothing found"
      else
        puts _list_status(todos)
      end
    end

    def status
      issues = merger(github_issues.all, todo_comments.all).changed
      if issues.empty?
        puts "Nothing new"
      else
        puts _list_status(issues)
      end
    end

    def diff
      issues = merger(github_issues.all, todo_comments.all).changed
      if issues.empty?
        puts "Nothing new"
      else
        puts _list_diff(issues)
      end
    end

    def commit
      issues = merger(github_issues.all, todo_comments.all).changed
      issues.each do |issue|
        issue.save
      end
    end

    def help
      puts "Available commands: status, diff, commit, help"
    end

    private

    def method_missing(command, *args, &block)
      puts "#{command}: Command not found"
      help
    end

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

    def todo_comments(config = @config)
      Models::TodoComment.use_repository(Models::TodoCommentRepository.new(
        config['dirs'],
        config['files']))
      Models::TodoComment
    end

    def github_issues(config = @config)
      Models::GithubIssue.use_repository(Models::GithubIssueRepository.new(
        config['github']['repo'],
        config['github']['login'],
        config['github']['password'],
        {:labels => config['github']['labels']})) 
      Models::GithubIssue
    end

    def merger(a, b)
      @merger ||= Models::Merger.new(a)
    end
  end
end