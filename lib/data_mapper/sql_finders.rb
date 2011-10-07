module DataMapper
  module SQLFinders
    include SQLHelper

    def by_sql(*additional_models, &block)
      sql, *bind_values = sql_query(self, *additional_models, &block)
      Collection.new(::DataMapper::Query.new(repository, self).tap { |q| q.send(:sql=, sql_parts(sql), bind_values) })
    end
  end
end
