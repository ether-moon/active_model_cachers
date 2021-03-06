# frozen_string_literal: true
module ActiveModelCachers
  module ActiveRecord
    class AttrModel
      attr_reader :klass, :column, :reflect

      def initialize(klass, column, primary_key: nil, foreign_key: nil)
        @klass = klass
        @column = column
        @primary_key = primary_key
        @foreign_key = foreign_key
        @reflect = klass.reflect_on_association(column)
      end

      def association?
        return (@reflect != nil)
      end

      def class_name
        return if not association?
        return @reflect.class_name
      end

      def join_table
        return nil if @reflect == nil
        options = @reflect.options
        return options[:through] if options[:through]
        return (options[:join_table] || @reflect.send(:derive_join_table)) if @reflect.macro == :has_and_belongs_to_many
        return nil
      end

      def join_table_class_name
        join_table.try{|table_name| @klass.reflect_on_association(table_name).try(:class_name)  || through_klass.name }
      end

      def through_reflection
        @klass.new.association(@column).reflection.through_reflection
      end

      def through_klass
        through_reflection.try(:klass) || through_klass_for_rails_3
      end

      def belongs_to?
        return false if not association?
        return @reflect.belongs_to?
      end

      def has_one?
        return false if not association?
        #return @reflect.has_one? # Rails 3 doesn't have this method
        return false if @reflect.collection?
        return false if @reflect.belongs_to?
        return true
      end

      def primary_key
        return @primary_key if @primary_key
        return if not association?
        return (@reflect.belongs_to? ? @reflect.klass : @reflect.active_record).primary_key
      end

      def foreign_key(reverse: false)
        return @foreign_key if @foreign_key
        return if not association?
        # key may be symbol if specify foreign_key in association options
        return @reflect.chain.last.foreign_key.to_s if reverse and join_table
        return (@reflect.belongs_to? == reverse ? primary_key : @reflect.foreign_key).to_s
      end

      def single_association?
        return false if not association?
        return !collection?
      end

      def collection?
        return false if not association?
        return @reflect.collection?
      end

      def query_model(binding, id)
        return query_self(binding, id) if @column == nil
        return query_association(binding, id) if association?
        return query_attribute(binding, id)
      end

      def extract_class_and_column
        return [class_name, nil] if single_association?
        return [@klass.to_s, @column]
      end

      private

      def query_self(binding, id)
        return binding if binding.is_a?(::ActiveRecord::Base)
        return @klass.find_by(primary_key => id)
      end

      def query_attribute(binding, id)
        return binding.send(@column) if binding.is_a?(::ActiveRecord::Base) and binding.has_attribute?(@column)
        return @klass.where(id: id).limit(1).pluck(@column).first
      end

      def query_association(binding, id)
        return binding.association(@column).load_target if binding.is_a?(::ActiveRecord::Base)
        id = @reflect.active_record.where(id: id).limit(1).pluck(foreign_key).first if foreign_key != 'id'
        case
        when collection? ; return id ? @reflect.klass.where(@reflect.foreign_key => id).to_a : []
        when has_one?    ; return id ? @reflect.klass.find_by(foreign_key(reverse: true) => id) : nil
        else             ; return id ? @reflect.klass.find_by(primary_key => id) : nil
        end
      end

      def through_klass_for_rails_3
        const_name = "HABTM_#{@reflect.klass.name.pluralize}"
        @klass.const_defined?(const_name) ? @klass.const_get(const_name) : @klass.const_set(const_name, create_through_klass_for_rails_3)
      end

      def create_through_klass_for_rails_3
        Class.new(::ActiveRecord::Base).tap{|s| s.table_name = join_table }
      end
    end
  end
end
