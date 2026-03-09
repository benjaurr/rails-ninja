module RailsNinja
  class API
    attr_reader :request

    def initialize(request = nil)
      @request = request
    end

    def params
      request&.params || {}
    end

    # --- Class-level DSL ---

    class << self
      # HTTP verb decorators
      %i[get post put patch delete].each do |verb|
        define_method(verb) do |path, **options|
          self._pending_route = { verb: verb, path: path, **options }
        end
      end

      # Schema definition DSL
      def schema(name, &block)
        klass = Class.new(Schema::Base)
        klass.class_eval(&block)

        # Register as a constant on this API class so it's accessible by name
        const_set(name, klass)
        _schemas[name] = klass
        klass
      end

      # Config DSL
      def title(value = nil)
        if value
          @_title = value
        else
          @_title
        end
      end

      def _title
        @_title
      end

      def version(value = nil)
        if value
          @_version = value
        else
          @_version
        end
      end

      def _version
        @_version
      end

      # Mount sub-APIs
      def mount(api_class, prefix: "/")
        _mounted_apis << { api_class: api_class, prefix: prefix }
      end

      # Storage
      def _endpoints
        @_endpoints ||= []
      end

      def _schemas
        @_schemas ||= {}
      end

      def _mounted_apis
        @_mounted_apis ||= []
      end

      def _pending_route
        @_pending_route
      end

      def _pending_route=(route)
        @_pending_route = route
      end

      # The decorator magic: when a method is defined after a verb call,
      # pair them together as an endpoint
      def method_added(method_name)
        super
        return if @_inside_method_added
        return unless _pending_route

        @_inside_method_added = true

        route_def = _pending_route.merge(handler: method_name, api_class: self)
        self._pending_route = nil

        _endpoints << Endpoint.new(**route_def)

        @_inside_method_added = false
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@_endpoints, [])
        subclass.instance_variable_set(:@_schemas, (_schemas || {}).dup)
        subclass.instance_variable_set(:@_mounted_apis, [])
      end

      # Rack interface — makes this class mountable
      def call(env)
        @_rack_app ||= Middleware.new(api_class: self)
        @_rack_app.call(env)
      end
    end
  end
end
