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
      conf = config
      conf['dir'] = args[1] if args[1]
      issues = todo_comments.all.map{|todo| github_issues(conf).new(todo.to_issue_attrs)}
      if issues.empty?
        puts "Nothing found"
      else
        puts _list_status(issues)
      end
    end

    def status(*args)
      issues = merger(github_issues.all, todo_comments.all).changed
      if issues.empty?
        puts "Nothing new"
      else
        puts _list_status(issues)
      end
    end

    def diff(*args)
      issues = merger(github_issues.all, todo_comments.all).changed
      if issues.empty?
        puts "Nothing new"
      else
        puts _list_diff(issues)
      end
    end

    def commit(*args)
      issues = merger(github_issues.all, todo_comments.all).changed
      issues.each do |issue|
        issue.save
      end
    end

    def help
      puts "Available commands: #{COMMANDS.join(", ")}"
    end

    private

    def unknown(command, *args, &block)
      puts "#{command}: Command not found"
      help
    end

    def max_length(list, attr)
      list.map(&attr).max{ |a,b| a.to_s.length <=> b.to_s.length}.to_s.length
    end

    def format_status(todos, todo)
      mod = sprintf "%#{max_length(todos, :modifier)}s   ", todo.modifier
      file = sprintf "%#{max_length(todos, :file)}s", todo.file
      begin_line = sprintf "%-#{max_length(todos, :begin_line)}s  ", todo.begin_line
      title = sprintf "%-#{max_length(todos, :title) + 8}s", todo.title
      "#      #{mod}#{title} #{file}:#{begin_line}"
    end


    def format_diff(todos, todo)
      mod = sprintf "%#{max_length(todos, :modifier)}s   ", todo.modifier
      file = sprintf "%#{max_length(todos, :file)}s", todo.file
      begin_line = sprintf "%-#{max_length(todos, :begin_line)}s  ", todo.begin_line
      title = sprintf "%-#{max_length(todos, :title) + 8}s", todo.title
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

    def todo_comments(config = config)
      Models::TodoComment.use_repository(Models::TodoCommentRepository.new(
        config['dir'],
        config['files']))
      Models::TodoComment
    end

    def github_issues(config = config)
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

    def config
      @config ||=
      begin
        config_file = ".issuebeaver.yml"
        config = DEFAULT_CONFIG.dup

        if File.readable?(config_file)
          config.merge!(YAML.load(File.read(config_file)))
        end
      end
    end

    DEFAULT_CONFIG =
      {
        'dir' => '.',
        'files' => '**/**.rb',
        'github' => {
          'repo' => '',
          'labels' => ['todo']
        }
      }

  end
end