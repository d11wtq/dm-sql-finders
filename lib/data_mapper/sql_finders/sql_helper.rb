module DataMapper
  module SQLFinders
    module SQLHelper
      class ShallowParser
        def initialize(sql)
          @sql = sql.dup.to_s
        end

        def parse
          tokens = {
            :select   => "SELECT",
            :from     => "FROM",
            :where    => "WHERE",
            :group_by => "GROUP BY",
            :having   => "HAVING",
            :order_by => "ORDER BY",
            :limit    => "LIMIT"
          }

          parts = {}

          tokens.each_with_index do |(key, initial), index|
            parts[key] = scan_chunk(initial, tokens.values[(index + 1)..-1])
          end

          parts
        end

        def scan_chunk(start_token, end_tokens)
          scan_until(end_tokens) if @sql =~ /^\s*#{start_token}\b/i
        end

        def scan_until(tokens, include_delimiters = true)
          delimiters = include_delimiters ? { "[" => "]", "(" => ")", "`" => "`", "'" => "'", '"' => '"', "--" => "\n", "/*" => "*/" } : { }
          alternates = ["\\"]
          alternates += delimiters.keys
          alternates += tokens.dup
          regex_body = alternates.map{ |v| Regexp.escape(v) }.join("|")
          pattern    = /^(?:\s+|#{regex_body}|\S)/i

          chunk = ""

          while result = pattern.match(@sql)
            token = result.to_s
            case token
              when /^\s+$/
                chunk << @sql.slice!(0, token.length)
              when "\\"
                chunk << @sql.slice!(0, 2) # escape consumes following character, always
              when *delimiters.keys
                chunk << @sql.slice!(0, token.length) << scan_until([delimiters[token]], false)
              when *tokens
                if include_delimiters
                  return chunk
                else
                  return chunk << @sql.slice!(0, token.length)
                end
              else
                chunk << @sql.slice!(0, token.length)
            end
          end

          chunk
        end
      end

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
        ShallowParser.new(sql_string).parse
      end
    end
  end
end
