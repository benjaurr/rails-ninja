module RailsNinja
  module Schema
    Field = Struct.new(:name, :type, :required, :default, keyword_init: true) do
      def initialize(name:, type:, required: true, default: nil)
        super(name: name, type: type, required: required, default: default)
      end
    end
  end
end
