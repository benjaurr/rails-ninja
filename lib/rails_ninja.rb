require "rack"
require "multi_json"
require "mustermann"

require_relative "rails_ninja/version"
require_relative "rails_ninja/errors"
require_relative "rails_ninja/schema/field"
require_relative "rails_ninja/schema/coercer"
require_relative "rails_ninja/schema/validator"
require_relative "rails_ninja/schema/serializer"
require_relative "rails_ninja/schema"
require_relative "rails_ninja/endpoint"
require_relative "rails_ninja/request"
require_relative "rails_ninja/response"
require_relative "rails_ninja/router"
require_relative "rails_ninja/middleware"
require_relative "rails_ninja/openapi/schema_ref"
require_relative "rails_ninja/openapi/generator"
require_relative "rails_ninja/swagger/ui"
require_relative "rails_ninja/api"
require_relative "rails_ninja/action"

require_relative "rails_ninja/railtie" if defined?(Rails::Railtie)

module RailsNinja
  def self.registered_apis
    @registered_apis ||= []
  end

  def self.generate_openapi(output: "public/openapi")
    require "fileutils"
    FileUtils.mkdir_p(output)

    registered_apis.each do |api_class|
      router = Router.new
      router.add_api(api_class)
      generator = OpenAPI::Generator.new(router, api_class)

      filename = api_class.name.split("::").last
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase + ".json"

      File.write(File.join(output, filename), generator.to_json)
    end
  end
end
