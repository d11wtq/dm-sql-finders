module DataMapper
  module SQLFinders
    module Query
      def sql=(parts, bind_values)
        @sql_parts  = parts
        @sql_values = bind_values
      end

      def sql
        @sql_parts  ||= {}
        @sql_values ||= []
        return @sql_parts, @sql_values
      end
    end
  end

  module Model
    def default_order(repository_name = default_repository_name)
      @default_order[repository_name] ||= key(repository_name).map { |property| Query::DefaultDirection.new(property) }.freeze
    end
  end

  class Query
    class DefaultDirection < Direction; end

    # Temporary monkey patch for https://github.com/datamapper/dm-core/pull/150
    def normalize_order
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

  Query.send(:include, SQLFinders::Query)
end
