module DataMapper
  module SQLFinders
    module SQLHelper
      def synthesize_table(model)
        # FIXME: Maybe provide a real class definition to make it possible for people to hook into?
        table = Class.new do
          define_method(:to_s) do
            repository.adapter.send(:quote_name, model.storage_name)
          end

          model.properties.each do |p|
            define_method(p.name) { "#{to_s}.#{repository.adapter.send(:quote_name, p.field)}" }
          end

          define_method(:*) do
            model.properties.map{ |p| "#{to_s}.#{repository.adapter.send(:quote_name, p.field)}" }.join(", ")
          end
        end

        table.new
      end

      def sql_query(*models)
        raise ArgumentError, "Block required" unless block_given?
        yield *models.map { |m| synthesize_table(m) }
      end

      def sql_parts(sql_string)
        SQLParser.new(sql_string).parse
      end
    end
  end
end
