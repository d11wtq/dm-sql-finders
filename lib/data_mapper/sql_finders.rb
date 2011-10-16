module DataMapper
  module SQLFinders
    def sql(*models)
      raise ArgumentError, "Block required" unless block_given?
      yield *TableRepresentation.from_models(*models)
    end

    def by_sql(*additional_models, &block)
      options = if additional_models.last.kind_of?(Hash)
        additional_models.pop
      else
        {}
      end

      sql, *bind_values = sql(self, *additional_models, &block)
      parts = SQLParser.new(sql).parse

      options[:limit]  ||= parts[:limit]  if parts[:limit]
      options[:offset] ||= parts[:offset] if parts[:offset]

      Collection.new(Query.new(repository, self, options).tap { |q| q.send(:sql=, parts, bind_values) })
    end
  end
end
