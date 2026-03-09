module RailsNinja
  module Schema
    class Serializer
      attr_reader :schema_class, :object

      def initialize(schema_class, object)
        @schema_class = schema_class
        @object = object
      end

      def call
        result = {}

        schema_class._fields.each do |name, field|
          value = read_attribute(object, name)

          result[name] = if field.type <= Schema::Base
            value.nil? ? nil : Serializer.new(field.type, value).call
          else
            value
          end
        end

        result
      end

      private

      def read_attribute(obj, name)
        if obj.is_a?(Hash)
          obj[name] || obj[name.to_s]
        elsif obj.respond_to?(name)
          obj.public_send(name)
        elsif obj.respond_to?(:[])
          obj[name] || obj[name.to_s]
        end
      end
    end
  end
end
