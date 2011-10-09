module DataMapper
  module SQLFinders
    include SQLHelper

    def by_sql(*additional_models, &block)
      options = if additional_models.last.kind_of?(Hash)
        additional_models.pop
      else
        {}
      end

      sql, *bind_values = sql_query(self, *additional_models, &block)
      parts = sql_parts(sql)

      options[:limit]  ||= parts[:limit]  if parts[:limit]
      options[:offset] ||= parts[:offset] if parts[:offset]

      Collection.new(::DataMapper::Query.new(repository, self, options).tap { |q| q.send(:sql=, parts, bind_values) })
    end
  end
end
