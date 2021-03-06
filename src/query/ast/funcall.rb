module Query
  module AST
    class Funcall < Term
      attr_reader :name

      def initialize(name, *arguments)
        @name = name
        @fn = SQL_CONFIG.functions.function(name)
        unless @fn
          @fn = SQL_CONFIG.aggregate_functions.function(name) or
            raise "Unknown function: #{name}"
          @aggregate = true
        end
        @arguments = arguments
      end

      def dup
        self.class.new(@name.dup, *arguments.map(&:dup))
      end

      def display_value(raw_value, format=nil)
        self.type.display_value(raw_value, format || @fn.display_format)
      end

      def aggregate?
        @aggregate
      end

      def argtypes
        @argtypes ||= @fn.argtypes
      end

      def typecheck!
        if @fn.arity != self.arity
          raise "Function #{@name} requires #{@fn.arity} arguments, called with #{arity}"
        end
        self.arguments.each_with_index { |arg, i|
          argtypes[i].type_match?(arg.type) or
            raise "Type mismatch in #{self}: for argument #{i + 1} (#{arg})"
        }
      end

      def convert_types!
        if @fn.arity != self.arity
          raise "Function '#{@name}' requires #{@fn.arity} arguments, called with #{arity}"
        end
        argtypes = @fn.argtypes
        i = -1
        self.arguments = self.arguments.map { |arg|
          i += 1
          arg.convert_to_type(argtypes[i])
        }
      end

      def kind
        :funcall
      end

      def type
        @fn.return_type(self.first)
      end

      def to_s
        "#{@name}(" + arguments.map(&:to_s).join(',') + ")"
      end

      def to_sql
        @fn.expr.gsub(/%s/) { |m| self.first.to_sql }.gsub(/:(\d+)\b/) { |m|
          arguments[$1.to_i - 1].to_sql
        }
      end
    end
  end
end
