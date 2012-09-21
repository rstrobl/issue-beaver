module IssueBeaver
  module Shared
    class LazyCollection < Enumerator
      def lazy_select(&block)
        Enumerator.new do |yielder|
          self.each do |element|
            yielder << element if yield(element)
          end
        end
      end

      def lazy_map(&block)
        Enumerator.new do |yielder|
          self.each do |element|
            yielder << yield(element)
          end
        end
      end
    end
  end
end
