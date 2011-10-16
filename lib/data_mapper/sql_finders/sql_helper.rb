module DataMapper
  module SQLFinders
    module SQLHelper
      class ShallowParser
        def initialize(sql)
          @sql = sql.dup.to_s
        end

        def parse
          tokens = {
            :select       => "SELECT",
            :from         => "FROM",
            :where        => "WHERE",
            :group_by     => "GROUP BY",
            :having       => "HAVING",
            :order_by     => "ORDER BY",
            :limit_offset => "LIMIT"
          }

          parts = {}

          tokens.each_with_index do |(key, initial), index|
            parts[key] = scan_chunk(initial, tokens.values[(index + 1)..-1])
          end

          parse_fields!(parts)
          parse_limit_offset!(parts)

          parts
        end

        private

        def scan_chunk(start_token, end_tokens)
          scan_until(@sql, end_tokens) if @sql =~ /^\s*#{start_token}\b/i
        end

        def scan_until(str, tokens, include_delimiters = true)
          delimiters = include_delimiters ? { "[" => "]", "(" => ")", "`" => "`", "'" => "'", '"' => '"', "--" => "\n", "/*" => "*/" } : { }
          alternates = ["\\"]
          alternates += delimiters.keys
          alternates += tokens.dup
          regex_body = alternates.map{ |v| v.kind_of?(Regexp) ? v.to_s : Regexp.escape(v) }.join("|")
          pattern    = /^(?:#{regex_body}|.)/i

          chunk = ""

          while result = pattern.match(str)
            token = result.to_s
            case token
              when "\\"
                chunk << str.slice!(0, 2) # escape consumes following character, always
              when *delimiters.keys
                chunk << str.slice!(0, token.length) << scan_until(str, [delimiters[token]], false)
              when *tokens
                if include_delimiters
                  return chunk
                else
                  return chunk << str.slice!(0, token.length)
                end
              else
                chunk << str.slice!(0, token.length)
            end
          end

          chunk
        end

        def parse_fields!(parts)
          return unless fragment = parts[:select]

          if m = /^\s*SELECT(?:\s+DISTINCT)?\s+(.*)/is.match(fragment)
            full_fields_str = m[1].dup
            fields_with_aliases = []
            while full_fields_str.length > 0
              fields_with_aliases << scan_until(full_fields_str, [","]).strip
              full_fields_str.slice!(0, 1) if full_fields_str.length > 0
            end
            parts[:fields] = fields_with_aliases.collect { |f| extract_field_name(f) }
          end
        end

        def extract_field_name(field)
          # simple hack: the last token in a SELECT expression is always (conveniently) the alias, regardless of whether an AS is used, or an alias even given at all
          full_str_rtl = field.dup.reverse
          qualified_alias_str_rtl = scan_until(full_str_rtl, [/\s+/])
          alias_str = scan_until(qualified_alias_str_rtl, ["."]).reverse
          case alias_str[0]
            when '"', '"', "`"
              alias_str[1...-1].gsub(/\\(.)/, "\\1")
            else
              alias_str
          end
        end

        def parse_limit_offset!(parts)
          return unless fragment = parts[:limit_offset]

          if m = /^\s*LIMIT\s+(\d+)\s*,\s*(\d+)/i.match(fragment)
            parts[:limit]  = m[2].to_i
            parts[:offset] = m[1].to_i
          elsif m = /^\s*LIMIT\s+(\d+)\s+OFFSET\s+(\d+)/i.match(fragment)
            parts[:limit]  = m[1].to_i
            parts[:offset] = m[2].to_i
          elsif m = /^\s*LIMIT\s+(\d+)/i.match(fragment)
            parts[:limit]  = m[1].to_i
          end
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
