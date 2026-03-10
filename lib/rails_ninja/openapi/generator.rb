module RailsNinja
  module OpenAPI
    class Generator
      def initialize(router, api_class)
        @router = router
        @api_class = api_class
      end

      def to_hash
        {
          openapi: "3.0.3",
          info: {
            title: @api_class._title || @api_class.name || "API",
            version: @api_class._version || "0.1.0"
          },
          paths: build_paths,
          components: { schemas: build_schemas }
        }
      end

      def to_json
        MultiJson.dump(to_hash)
      end

      private

      def build_paths
        grouped = @router.routes.group_by { |r| r[:pattern].to_s }

        grouped.each_with_object({}) do |(path, routes), paths|
          openapi_path = path.gsub(/:(\w+)/, '{\1}')
          paths[openapi_path] = {}

          routes.each do |route|
            endpoint = route[:endpoint]
            verb = endpoint.verb.to_s.downcase

            operation = {
              summary: endpoint.summary,
              operationId: endpoint.handler.to_s,
              tags: endpoint.tags,
              responses: build_responses(endpoint)
            }

            if endpoint.request_schema
              operation[:requestBody] = build_request_body(endpoint.request_schema)
            end

            params = extract_path_params(path) + extract_header_params(endpoint)
            operation[:parameters] = params if params.any?

            paths[openapi_path][verb] = operation
          end
        end
      end

      def build_responses(endpoint)
        if endpoint.response_schema
          schema = if endpoint.response_is_array?
            { type: "array", items: SchemaRef.to_json_schema(endpoint.response_schema_class) }
          else
            SchemaRef.to_json_schema(endpoint.response_schema)
          end

          {
            "200" => {
              description: "Successful response",
              content: { "application/json" => { schema: schema } }
            }
          }
        else
          { "200" => { description: "Successful response" } }
        end
      end

      def build_request_body(schema)
        {
          required: true,
          content: {
            "application/json" => {
              schema: SchemaRef.to_json_schema(schema)
            }
          }
        }
      end

      def extract_path_params(path)
        path.scan(/:(\w+)/).flatten.map do |param|
          { name: param, in: "path", required: true, schema: { type: "string" } }
        end
      end

      def extract_header_params(endpoint)
        return [] unless endpoint.header_params&.any?

        endpoint.header_params.map do |h|
          { name: h[:name], in: "header", required: h[:required], schema: h[:schema] }
        end
      end

      def build_schemas
        collect_schemas.each_with_object({}) do |schema_class, schemas|
          name = schema_class.name || schema_class.object_id.to_s
          schemas[name] = SchemaRef.schema_to_json_schema(schema_class)
        end
      end

      def collect_schemas
        schemas = Set.new

        @router.routes.each do |route|
          endpoint = route[:endpoint]
          schemas << endpoint.request_schema if endpoint.request_schema
          if endpoint.response_schema
            schemas << endpoint.response_schema_class
          end
        end

        schemas
      end
    end
  end
end
