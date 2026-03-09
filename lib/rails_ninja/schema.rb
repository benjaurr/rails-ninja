module RailsNinja
  module Schema
    class Base
      class << self
        def field(name, type, required: true, default: nil)
          _fields[name.to_sym] = Field.new(
            name: name.to_sym,
            type: type,
            required: required,
            default: default
          )
        end

        def _fields
          @_fields ||= {}
        end

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@_fields, _fields.dup)
        end

        def validate(data)
          Validator.new(self, data).call
        end

        def serialize(object)
          Serializer.new(self, object).call
        end

        def serialize_many(collection)
          collection.map { |obj| serialize(obj) }
        end
      end
    end
  end
end
