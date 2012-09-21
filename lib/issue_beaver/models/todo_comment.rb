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
      ATTRIBUTES = [:title, :body, :begin_line, :file, :created_at, :updated_at, :assignee]

      def initialize(attrs = {})
        @attributes = Hashie::Mash.new(attrs)
        ATTRIBUTES.each do |attr| @attributes[attr] ||= nil end
      end

      def to_issue_attrs
        Hashie::Mash.new(attributes.only(:title, :body, :begin_line, :file, :created_at, :updated_at, :assignee))
      end
    end

    class TodoCommentRepository
      def initialize(dir, files)
        @dir = dir
        file_pattern = "{#{[@dir].map{|dir|File.expand_path(dir)}.join(',')}}/#{files}"
        @files = Dir.glob(file_pattern)
      end

      def all
        @todos ||= enum_scanned_files(@files)
      end

      private

      def enum_scanned_files(files)
        Shared::LazyCollection.new do |yielder|
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
        TodoComment.new(attrs)
      end

      def relative_path(file)
        Pathname.new(File.absolute_path(file)).
          relative_path_from(Pathname.new(File.absolute_path(@dir))).to_s
      end
    end
  end
end