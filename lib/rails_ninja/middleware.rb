module RailsNinja
  class Middleware
    def initialize(api_class:)
      @router = Router.new
      @router.add_api(api_class)
      @api_class = api_class
      @openapi_generator = OpenAPI::Generator.new(@router, api_class)
    end

    def call(env)
      path = env["PATH_INFO"] || "/"
      verb = env["REQUEST_METHOD"]

      return serve_openapi_spec if path == "/openapi.json" && verb == "GET"
      return serve_swagger_ui if path == "/docs" && verb == "GET"

      result = @router.match(verb, path)
      return Response.error("Not Found", status: 404) unless result

      endpoint, path_params = result
      request = Request.new(env, path_params)
      api_instance = endpoint.api_class.new(request)
      endpoint.call(api_instance, request)
    rescue ValidationError => e
      Response.json({ errors: e.errors }, status: 422)
    rescue NotFoundError => e
      Response.error(e.message, status: 404)
    rescue StandardError => e
      Response.error("Internal Server Error", status: 500)
    end

    private

    def serve_openapi_spec
      Response.json(@openapi_generator.to_hash)
    end

    def serve_swagger_ui
      Response.html(Swagger::UI.html(spec_url: "./openapi.json"))
    end
  end
end
