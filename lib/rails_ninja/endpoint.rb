module RailsNinja
  class Endpoint
    attr_reader :verb, :path, :handler, :api_class,
                :request_schema, :response_schema, :tags, :summary, :header_params

    def initialize(verb:, path:, handler:, api_class:, request: nil, response: nil, tags: nil, summary: nil, headers: nil)
      @verb = verb
      @path = path
      @handler = handler
      @api_class = api_class
      @request_schema = request
      @response_schema = response
      @tags = tags || [api_class.name&.gsub(/Api$/, "")].compact
      @summary = summary || handler.to_s.tr("_", " ").capitalize
      @header_params = merge_headers(api_class._headers, headers)
    end

    def call(api_instance, request)
      halted = run_before_actions(api_instance)
      return halted if halted

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

    def run_before_actions(api_instance)
      api_class._before_actions.each do |action|
        result = if action.is_a?(Symbol)
          api_instance.public_send(action)
        else
          api_instance.instance_exec(&action)
        end

        return result if rack_response?(result)
        return serialize_response(result) if status_code?(result)
      end

      nil
    end

    def validate_request!(request)
      schema = request_schema
      coerced, errors = schema.validate(request.body_params)
      raise ValidationError, errors if errors.any?

      request.validated_data = coerced
    end

    def merge_headers(class_headers, endpoint_headers)
      parsed_class = parse_headers(class_headers)
      parsed_endpoint = parse_headers(endpoint_headers)

      # Endpoint-level headers override class-level headers with the same name
      merged = parsed_class.reject { |ch| parsed_endpoint.any? { |eh| eh[:name] == ch[:name] } }
      merged + parsed_endpoint
    end

    def parse_headers(headers)
      return [] if headers.nil?

      Array(headers).map do |h|
        if h.is_a?(String)
          { name: h, required: true, schema: { type: "string" } }
        elsif h.is_a?(Hash)
          { name: h[:name], required: h.fetch(:required, true), schema: { type: h.fetch(:type, "string") } }
        end
      end.compact
    end

    def rack_response?(result)
      result.is_a?(Array) && result.length == 3 && result[0].is_a?(Integer)
    end

    def status_code?(result)
      result.is_a?(Integer) && result.between?(100, 599)
    end

    def serialize_response(result)
      return result if rack_response?(result)
      return Response.json(nil, status: result) if status_code?(result)
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
