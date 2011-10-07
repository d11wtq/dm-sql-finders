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

  Query.send(:include, SQLFinders::Query)
end
