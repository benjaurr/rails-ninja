module RailsNinja
  module Schema
    class Validator
      attr_reader :schema_class, :data

      def initialize(schema_class, data)
        @schema_class = schema_class
        @data = data || {}
      end

      def call
        errors = []
        coerced = {}

        schema_class._fields.each do |name, field|
          value = data[name] || data[name.to_s]

          if value.nil?
            if field.required && field.default.nil?
              errors << "#{name} is required"
              next
            end
            value = field.default
          end

          next if value.nil?

          if field.type <= Schema::Base
            result, nested_errors = field.type.validate(value)
            if nested_errors.any?
              errors.concat(nested_errors.map { |e| "#{name}.#{e}" })
            else
              coerced[name] = result
            end
          else
            coerced[name] = Coercer.coerce(value, field.type)
          end
        rescue ValidationError => e
          errors.concat(e.errors.map { |err| "#{name}: #{err}" })
        end

        [coerced, errors]
      end
    end
  end
end
