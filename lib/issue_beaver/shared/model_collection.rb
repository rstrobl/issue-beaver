module IssueBeaver
  module Shared
    class ModelCollection
      def initialize(model, array)
        @model = model
        @array = array
      end

      def dup
        self.class.new(@model, @array.dup)
      end

      def method_missing(name, *args, &block)
        if @model.respond_to?(name)
          target = @model
        else
          target = @array
        end
        target.send(name, *args, &block)
      end
    end
  end
end