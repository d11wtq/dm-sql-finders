module DataMapper
  module SQLFinders
    class Query < DataMapper::Query
      def sql=(parts, bind_values)
        @sql_parts  = parts
        @sql_values = bind_values
      end

      def sql
        @sql_parts  ||= {}
        @sql_values ||= []
        return @sql_parts, @sql_values
      end

      def fields
        return super unless @sql_parts && @sql_parts[:fields]

        @sql_parts[:fields].map do |field|
          if property = model.properties.detect { |p| p.field == field }
            property
          else
            DataMapper::Property::String.new(model, field)
          end
        end
      end

      class DefaultDirection < Direction; end
    end
  end

  module Model
    def default_order(repository_name = default_repository_name)
      @default_order[repository_name] ||= key(repository_name).map { |property| SQLFinders::Query::DefaultDirection.new(property) }.freeze
    end
  end

  class Query
    def normalize_order # temporary (will be removed in DM 1.3)
      return if @order.nil?

      @order = Array(@order)
      @order = @order.map do |order|
        case order
          when Direction
            order.dup

          when Operator
            target   = order.target
            property = target.kind_of?(Property) ? target : @properties[target]

            Direction.new(property, order.operator)

          when Symbol, String
            Direction.new(@properties[order])

          when Property
            Direction.new(order)

          when Path
            Direction.new(order.property)
        end
      end
    end
  end
end
