module DataMapper
  class Adapters::DataObjectsAdapter
    def select_statement(query)
      SQLFinders::SQLBuilder.new(self, query).select_statement
    end
  end
end
