# frozen_string_literal: true
module ActiveModelCachers
  class Config
    attr_accessor :store
    attr_accessor :cache_from_loaded_associations

    def initialize
      @cache_from_loaded_associations = true
    end
  end
end
