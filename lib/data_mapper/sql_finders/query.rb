module DataMapper
  module SQLFinders
    class ::DataMapper::Query
      attr_reader :sql_parts
      attr_reader :sql_bind_values

      def initialize_with_sql(repository, model, options = {})
        options = options.dup
        @sql_parts       = options.delete(:sql_parts)
        @sql_bind_values = options.delete(:sql_bind_values)
        initialize_without_sql(repository, model, options)
      end

      alias_method :initialize_without_sql, :initialize
      alias_method :initialize, :initialize_with_sql

      def inspect
        attrs = [
          [ :repository, repository.name ],
          [ :model,      model           ],
          [ :fields,     fields          ],
          [ :links,      links           ],
          [ :conditions, conditions      ],
          [ :sql_parts,  sql_parts       ],
          [ :order,      order           ],
          [ :limit,      limit           ],
          [ :offset,     offset          ],
          [ :reload,     reload?         ],
          [ :unique,     unique?         ],
        ]

        "#<#{self.class.name} #{attrs.map { |key, value| "@#{key}=#{value.inspect}" }.join(' ')}>"
      end
    end
  end
end
