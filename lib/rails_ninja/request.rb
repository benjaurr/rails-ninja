module RailsNinja
  class Request
    attr_reader :env, :path_params
    attr_accessor :validated_data

    def initialize(env, path_params = {})
      @env = env
      @path_params = (path_params || {}).transform_keys(&:to_sym)
      @rack_request = Rack::Request.new(env)
      @validated_data = nil
    end

    def params
      @params ||= path_params
        .merge(query_params)
        .merge(body_params)
        .merge(validated_data || {})
    end

    def query_params
      @query_params ||= @rack_request.GET.transform_keys(&:to_sym)
    end

    def body_params
      @body_params ||= parse_body
    end

    def headers
      @headers ||= env.each_with_object({}) do |(key, value), hash|
        next unless key.start_with?("HTTP_")

        header = key.sub("HTTP_", "").split("_").map(&:capitalize).join("-")
        hash[header] = value
      end
    end

    def content_type
      env["CONTENT_TYPE"]
    end

    private

    def parse_body
      return {} unless content_type&.include?("application/json")

      body = @rack_request.body.read
      @rack_request.body.rewind
      return {} if body.nil? || body.empty?

      MultiJson.load(body, symbolize_keys: true)
    rescue MultiJson::ParseError
      {}
    end
  end
end
