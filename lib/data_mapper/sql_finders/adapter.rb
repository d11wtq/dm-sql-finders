module DataMapper
  class Adapters::DataObjectsAdapter
    def select_statement_with_query(query)
      SQLFinders::SQLBuilder.new(self, query).select_statement
    end

    alias_method :select_statement_without_query, :select_statement
    alias_method :select_statement, :select_statement_with_query
  end
end
