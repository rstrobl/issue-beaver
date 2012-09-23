require 'pathname'
require 'active_support/core_ext' # Needed for delegate
require 'active_model'
require 'hashie'
require 'enumerable/lazy'
require 'enumerator/memoizing'

module IssueBeaver
  module Models
    class TodoComments

      def initialize(root_dir, files)
        @root_dir = root_dir
        @files = files
      end


      def all
        @todos ||= enum_scanned_files(@files).memoizing.lazy
      end


      private

      # TODO: Allow individual TODOs to follow right after each other without newline in between
      def enum_scanned_files(files)
        Enumerator.new do |yielder|
          todos = []
          parser = Grammars::RubyCommentsParser.new
        
          files.each do |file|
            content = File.read(file)
            parser.parse(content).comments.each{|comment| 
              yielder << new_todo(
                comment.merge('file' => relative_path(file),
                              'created_at' => File.ctime(file),
                              'updated_at' => File.ctime(file)
                              ))
            }
          end
        end
      end


      def new_todo(attrs)
        GithubIssue.new_from_todo(attrs)
      end


      def relative_path(file)
        Pathname.new(File.absolute_path(file)).
          relative_path_from(Pathname.new(File.absolute_path(@root_dir))).to_s
      end

    end
  end
end