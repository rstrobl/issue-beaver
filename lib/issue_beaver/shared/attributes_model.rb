require 'active_support/concern'
require 'active_model'

module IssueBeaver
  module Shared
    module AttributesModel

      extend ActiveSupport::Concern

      
      included do
      
        attr_accessor :attributes
      
        include ActiveModel::AttributeMethods
      
        include ActiveModel::Dirty
      
        attribute_method_suffix '='

      
        def attribute(key)
          attributes[key]
        end

      
        def attribute=(key, value)
          attribute_will_change!(key) unless value == attributes[key]
          attributes[key] = value
        end

      
        def update_attributes(attrs)
          attrs.each do |key, value|
            send(:attribute=, key, value)
          end
        end

      
        def modifier
          if new?
            "added"
          elsif changed?
            "modified"
          end
        end
      
      end
    end
  end
end