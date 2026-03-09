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
end
