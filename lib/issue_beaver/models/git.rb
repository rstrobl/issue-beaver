require 'grit'

module IssueBeaver
  module Models
    class Git

      def initialize(dir, repo_name)
        @root_dir = discover_root_dir(dir)
        @git = Grit::Repo.new(@root_dir)
        @repo_name = repo_name || @git.config['issuebeaver.repository'] || 'remote.origin'
      end

      attr_reader :root_dir


      def slug
        @slug ||= discover_github_repo(@repo_name)
      end


      def github_user
        @github_user ||= @git.config['github.user']
      end

      def labels
        @labels ||= (@git.config['issuebeaver.labels'] || "").split(',')
      end


      def discover_github_repo(repo_name)
        github_repo = nil
        if repo_name.match(/[^\.]+\/[^\.]+/)
          github_repo = repo_name
        else
          url = @git.config["#{repo_name}.url"]
          github_repo = url.match(/git@github\.com:([^\.]+)\.git/)[1] if url
        end
        github_repo
      end


      def files(dir)
        IO.popen(%Q{cd "#{@root_dir}" && git ls-files "#{dir}"}).lazy.memoizing.map(&:chomp).lazy
      end


      private

      def discover_root_dir(dir)
        cd = dir
        loop do
          return nil if !Dir.exists?(cd)
          return nil if File.absolute_path(cd) == '/'
          return cd if Dir.exists?(File.join(cd, '.git'))
          cd = File.join(cd, '..')
        end
        return nil
      end

    end
  end
end