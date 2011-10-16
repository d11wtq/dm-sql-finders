module DataMapper
  module SQLFinders
    class TableRepresentation
      class << self
        def from_models(*models)
          seen = {}
          models.map do |model|
            seen[model] ||= -1
            new(model, seen[model] += 1)
          end
        end
      end

      def initialize(model, idx = 0)
        @model = model
        @idx   = idx
      end

      def to_s
        @model.repository.adapter.send(:quote_name, @model.storage_name).dup.tap do |tbl|
          tbl << " AS #{storage_alias}" unless tbl == storage_alias
        end
      end

      def storage_alias
        name = @model.storage_name.dup.tap do |name|
          name << "_#{@idx}" if @idx > 0
        end
        @model.repository.adapter.send(:quote_name, name)
      end

      def *
        @model.properties.map { |p| "#{storage_alias}.#{@model.repository.adapter.send(:quote_name, p.field)}" }.join(", ")
      end

      def method_missing(name, *args, &block)
        return super unless args.size == 0 && !block_given?

        if property = @model.properties[name]
          "#{storage_alias}.#{@model.repository.adapter.send(:quote_name, property.field)}"
        elsif @model.method_defined?(name)
          @model.repository.adapter.send(:quote_name, name)
        else
          super
        end
      end
    end
  end
end
