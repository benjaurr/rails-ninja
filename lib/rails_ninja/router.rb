module RailsNinja
  class Router
    attr_reader :routes

    def initialize
      @routes = []
    end

    def add_api(api_class, prefix: "/")
      api_class._endpoints.each do |endpoint|
        full_path = normalize_path("#{prefix}/#{endpoint.path}")
        @routes << {
          pattern: Mustermann.new(full_path, type: :sinatra),
          endpoint: endpoint
        }
      end

      api_class._mounted_apis.each do |mounted|
        sub_prefix = normalize_path("#{prefix}/#{mounted[:prefix]}")
        add_api(mounted[:api_class], prefix: sub_prefix)
      end
    end

    def match(verb, path)
      @routes.each do |route|
        next unless route[:endpoint].verb.to_s.upcase == verb.upcase

        params = route[:pattern].params(path)
        next unless params

        return [route[:endpoint], params]
      end

      nil
    end

    private

    def normalize_path(path)
      "/" + path.gsub(%r{/+}, "/").gsub(%r{^/|/$}, "")
    end
  end
end
