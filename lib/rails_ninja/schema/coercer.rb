module RailsNinja
  module Schema
    module Coercer
      module_function

      def coerce(value, type)
        return value if value.is_a?(type) rescue false
        return nil if value.nil?

        case type.name
        when "Integer"
          Integer(value)
        when "Float"
          Float(value)
        when "String"
          String(value)
        when "TrueClass", "FalseClass"
          coerce_boolean(value)
        else
          if type <= Schema::Base
            # Nested schema — validate as hash
            value
          else
            value
          end
        end
      rescue ArgumentError, TypeError
        raise ValidationError, ["Cannot coerce #{value.inspect} to #{type}"]
      end

      def coerce_boolean(value)
        case value
        when true, "true", "1", 1 then true
        when false, "false", "0", 0 then false
        else
          raise ArgumentError, "Cannot coerce #{value.inspect} to Boolean"
        end
      end
    end
  end
end
