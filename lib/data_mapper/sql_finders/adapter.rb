module DataMapper
  module SQLFinders
    class SQLBuilder
      def initialize(adapter, query)
        @adapter                      = adapter
        @query                        = query
        @model                        = @query.model
        @parts, @sql_values           = @query.sql
        @fields                       = @query.fields
        @conditions                   = @query.conditions
        @qualify                      = @query.links.any? || !@parts[:from].nil?
        @conditions_stmt, @qry_values = @adapter.send(:conditions_statement, @conditions, @qualify)
        @order_by                     = @query.order
        @limit                        = @query.limit
        @offset                       = @query.offset
        @bind_values                  = @sql_values + @qry_values
        @group_by = if @query.unique?
          @fields.select { |property| property.kind_of?(Property) }
        end
      end

      def select_statement
        statement = [
          columns_fragment,
          from_fragment,
          join_fragment,
          where_fragment,
          group_fragment,
          order_fragment
        ].compact.join(" ")

        @adapter.send(:add_limit_offset!, statement, @limit, @offset, @bind_values)

        return statement, @bind_values
      end

      private

      def columns_fragment
        if @parts[:select]
          @parts[:select].strip
        else
          "SELECT #{@adapter.send(:columns_statement, @fields, @qualify)}"
        end
      end

      def from_fragment
        if @parts[:from]
          @parts[:from].strip
        else
          "FROM #{@adapter.send(:quote_name, @model.storage_name(@adapter.name))}"
        end
      end

      def join_fragment
        @adapter.send(:join_statement, @query, @bind_values, @qualify) if @query.links.any?
      end

      def where_fragment
        if @parts[:where]
          [@parts[:where].strip, @conditions_stmt].reject{ |c| DataMapper::Ext.blank?(c) }.join(" AND ")
        else
          "WHERE #{@conditions_stmt}" unless DataMapper::Ext.blank?(@conditions_stmt)
        end
      end

      def group_fragment
        if @parts[:group_by]
          @parts[:group_by].strip
        else
          "GROUP BY #{@adapter.send(:columns_statement, @group_by, @qualify)}" if @group_by && @group_by.any?
        end
      end

      def order_fragment
        if @parts[:order_by] && @order_by.all? { |o| o.kind_of?(::DataMapper::Query::DefaultDirection) }
          @parts[:order_by].strip
        else
          "ORDER BY #{@adapter.send(:order_statement, @order_by, @qualify)}" if @order_by && @order_by.any?
        end
      end
    end
  end

  class Adapters::DataObjectsAdapter
    def select_statement(query)
      SQLFinders::SQLBuilder.new(self, query).select_statement
    end
  end
end
