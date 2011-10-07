module DataMapper
  module SQLFinders
    include SQLHelper
    
    def by_sql(*additional_models, &block)
      sql, *bind_values = sql_query(self, *additional_models, &block)
      Collection.new(Query.new(repository, self, :sql_parts => sql_parts(sql), :sql_bind_values => bind_values))
    end
  end
end
