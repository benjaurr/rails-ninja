module RailsNinja
  class Endpoint
    attr_reader :verb, :path, :handler, :api_class,
                :request_schema, :response_schema, :tags, :summary

    def initialize(verb:, path:, handler:, api_class:, request: nil, response: nil, tags: nil, summary: nil)
      @verb = verb
      @path = path
      @handler = handler
      @api_class = api_class
      @request_schema = request
      @response_schema = response
      @tags = tags || [api_class.name&.gsub(/Api$/, "")].compact
      @summary = summary || handler.to_s.tr("_", " ").capitalize
    end

    def call(api_instance, request)
      validate_request!(request) if request_schema

      result = api_instance.public_send(handler)

      serialize_response(result)
    end

    def response_is_array?
      response_schema.is_a?(Array)
    end

    def response_schema_class
      response_is_array? ? response_schema.first : response_schema
    end

    private

    def validate_request!(request)
      schema = request_schema
      coerced, errors = schema.validate(request.body_params)
      raise ValidationError, errors if errors.any?

      request.validated_data = coerced
    end

    def serialize_response(result)
      return Response.json(result) unless response_schema

      body = if response_is_array?
        response_schema.first.serialize_many(result)
      else
        response_schema.serialize(result)
      end

      Response.json(body)
    end
  end
end
