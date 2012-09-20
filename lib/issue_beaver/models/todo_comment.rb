require 'pathname'
require 'active_support/core_ext' # Needed for delegate
require 'active_model'
require 'hashie'

module IssueBeaver
  module Models
    class TodoComment
      def self.use_repository(repository)
        @repository = repository
        class << self
          delegate :all, to: :@repository
        end
      end

      include Shared::AttributesModel
      ATTRIBUTES = [:title, :body, :begin_line, :file, :created_at, :updated_at]

      def initialize(attrs = {})
        @attributes = Hashie::Mash.new(attrs)
        ATTRIBUTES.each do |attr| @attributes[attr] ||= nil end
      end

      def to_issue_attrs
        Hashie::Mash.new(attributes.only(:title, :body, :begin_line, :file, :created_at, :updated_at))
      end
    end

    class TodoCommentRepository
      def initialize(dirs, files)
        file_pattern = "{#{dirs.join(',')}}/#{files}"
        @files = Dir.glob(File.expand_path(file_pattern))
      end

      def all
        @todos ||= scan_files(@files)
      end

      private

      def scan_files(files)
        todos = []
        parser = Grammars::RubyCommentsParser.new
        
        files.each do |file|
          content = File.read(file)
          new_todos = parser.parse(content).comments.map{|comment| 
            new_todo( comment.merge('file' => relative_path(file),
                                    'created_at' => File.ctime(file),
                                    'updated_at' => File.ctime(file)
                                    ))
          }
          todos << new_todos
        end

        todos.flatten
      end

      def new_todo(attrs)
        TodoComment.new(attrs)
      end

      def relative_path(file)
        Pathname.new(File.absolute_path(file)).
          relative_path_from(Pathname.pwd).to_s
      end
    end
  end
end