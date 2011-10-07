module DataMapper
  module SQLFinders
    class ::DataMapper::Adapters::DataObjectsAdapter
      def select_statement(query)
        order_by = query.order

        conditions_statement, bind_values = conditions_statement(query.conditions, query.links.any?)
        sql_parts, sql_bind_values = query.sql

        statement = [
          select_columns_fragment(query),
          select_from_fragment(query),
          select_join_fragment(query),
          select_where_fragment(query),
          select_group_fragment(query)
        ].compact.join(" ")

#        statement << " ORDER BY #{order_statement(order_by, qualify)}"   if order_by && order_by.any?

#        add_limit_offset!(statement, query.limit, query.offset, bind_values)

        return statement, sql_bind_values + bind_values
      end

      def select_columns_fragment(query)
        sql_parts, sql_bind_values = query.sql
        if sql_parts[:select]
          sql_parts[:select].strip
        else
          "SELECT #{columns_statement(query.fields, query.links.any?)}"
        end
      end

      def select_from_fragment(query)
        sql_parts, sql_bind_values = query.sql
        if sql_parts[:from]
          sql_parts[:from].strip
        else
          "FROM #{quote_name(query.model.storage_name(name))}"
        end
      end

      def select_join_fragment(query)
        qualify = query.links.any?
        conditions_statement, bind_values = conditions_statement(query.conditions, qualify)
        join_statement(query, bind_values, qualify) if qualify
      end

      def select_where_fragment(query)
        sql_parts, sql_bind_values = query.sql
        conditions_statement, bind_values = conditions_statement(query.conditions, query.links.any?)
        if sql_parts[:where]
          sql_parts[:where].strip
        else
          "WHERE #{conditions_statement}" unless DataMapper::Ext.blank?(conditions_statement)
        end
      end

      def select_group_fragment(query)
        sql_parts, sql_bind_values = query.sql
        group_by = if query.unique?
          query.fields.select { |property| property.kind_of?(Property) }
        end

        if sql_parts[:group_by]
          sql_parts[:group_by].strip
        else
          "GROUP BY #{columns_statement(group_by, qualify)}" if group_by && group_by.any?
        end
      end
    end
  end
end
