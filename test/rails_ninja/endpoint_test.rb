require "test_helper"

class EndpointTest < Minitest::Test
  def test_endpoint_summary_from_handler
    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items",
      handler: :list_items,
      api_class: RailsNinja::API
    )

    assert_equal "List items", endpoint.summary
  end

  def test_endpoint_response_is_array
    schema = Class.new(RailsNinja::Schema::Base) do
      field :id, Integer
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items",
      handler: :list_items,
      api_class: RailsNinja::API,
      response: [schema]
    )

    assert endpoint.response_is_array?
    assert_equal schema, endpoint.response_schema_class
  end

  def test_endpoint_call_with_response_schema
    schema = Class.new(RailsNinja::Schema::Base) do
      field :id, Integer
      field :name, String
    end

    api_class = Class.new(RailsNinja::API) do
      define_method(:get_item) do
        { id: 1, name: "Widget" }
      end
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items/:id",
      handler: :get_item,
      api_class: api_class,
      response: schema
    )

    env = Rack::MockRequest.env_for("/items/1", method: "GET")
    request = RailsNinja::Request.new(env, { id: "1" })
    api_instance = api_class.new(request)

    status, headers, body = endpoint.call(api_instance, request)

    assert_equal 200, status
    parsed = MultiJson.load(body.first, symbolize_keys: true)
    assert_equal 1, parsed[:id]
    assert_equal "Widget", parsed[:name]
  end

  def test_rack_response_passthrough
    api_class = Class.new(RailsNinja::API) do
      define_method(:unauthorized) do
        RailsNinja::Response.error("Unauthorized", status: 401)
      end
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/secret",
      handler: :unauthorized,
      api_class: api_class,
      response: Class.new(RailsNinja::Schema::Base) { field :id, Integer }
    )

    env = Rack::MockRequest.env_for("/secret", method: "GET")
    request = RailsNinja::Request.new(env, {})
    api_instance = api_class.new(request)

    status, headers, body = endpoint.call(api_instance, request)

    assert_equal 401, status
    assert_equal "application/json", headers["content-type"]
    parsed = MultiJson.load(body.first, symbolize_keys: true)
    assert_equal "Unauthorized", parsed[:error]
  end

  def test_rack_response_passthrough_without_schema
    api_class = Class.new(RailsNinja::API) do
      define_method(:not_found) do
        RailsNinja::Response.error("Not found", status: 404)
      end
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items/:id",
      handler: :not_found,
      api_class: api_class
    )

    env = Rack::MockRequest.env_for("/items/999", method: "GET")
    request = RailsNinja::Request.new(env, { id: "999" })
    api_instance = api_class.new(request)

    status, _headers, body = endpoint.call(api_instance, request)

    assert_equal 404, status
    parsed = MultiJson.load(body.first, symbolize_keys: true)
    assert_equal "Not found", parsed[:error]
  end

  def test_hash_return_not_treated_as_rack_response
    schema = Class.new(RailsNinja::Schema::Base) do
      field :id, Integer
    end

    api_class = Class.new(RailsNinja::API) do
      define_method(:get_item) do
        { id: 42 }
      end
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items/:id",
      handler: :get_item,
      api_class: api_class,
      response: schema
    )

    env = Rack::MockRequest.env_for("/items/42", method: "GET")
    request = RailsNinja::Request.new(env, { id: "42" })
    api_instance = api_class.new(request)

    status, _headers, body = endpoint.call(api_instance, request)

    assert_equal 200, status
    parsed = MultiJson.load(body.first, symbolize_keys: true)
    assert_equal 42, parsed[:id]
  end

  def test_bare_status_code_401
    api_class = Class.new(RailsNinja::API) do
      define_method(:unauthorized) { 401 }
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/secret", handler: :unauthorized, api_class: api_class
    )

    env = Rack::MockRequest.env_for("/secret", method: "GET")
    request = RailsNinja::Request.new(env, {})
    status, headers, body = endpoint.call(api_class.new(request), request)

    assert_equal 401, status
    assert_equal "application/json", headers["content-type"]
    assert_equal "null", body.first
  end

  def test_bare_status_code_204
    api_class = Class.new(RailsNinja::API) do
      define_method(:no_content) { 204 }
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :delete, path: "/items/:id", handler: :no_content, api_class: api_class
    )

    env = Rack::MockRequest.env_for("/items/1", method: "DELETE")
    request = RailsNinja::Request.new(env, { id: "1" })
    status, _headers, _body = endpoint.call(api_class.new(request), request)

    assert_equal 204, status
  end

  def test_bare_status_code_not_confused_with_integer_data
    schema = Class.new(RailsNinja::Schema::Base) { field :count, Integer }

    api_class = Class.new(RailsNinja::API) do
      define_method(:get_count) { { count: 200 } }
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/count", handler: :get_count, api_class: api_class, response: schema
    )

    env = Rack::MockRequest.env_for("/count", method: "GET")
    request = RailsNinja::Request.new(env, {})
    status, _headers, body = endpoint.call(api_class.new(request), request)

    assert_equal 200, status
    parsed = MultiJson.load(body.first, symbolize_keys: true)
    assert_equal 200, parsed[:count]
  end

  def test_header_params_from_strings
    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items",
      handler: :list_items,
      api_class: RailsNinja::API,
      headers: ["X-API-KEY", "X-MESSAGE-UUID"]
    )

    assert_equal 2, endpoint.header_params.size
    assert_equal "X-API-KEY", endpoint.header_params[0][:name]
    assert_equal true, endpoint.header_params[0][:required]
    assert_equal({ type: "string" }, endpoint.header_params[0][:schema])
    assert_equal "X-MESSAGE-UUID", endpoint.header_params[1][:name]
  end

  def test_header_params_from_hashes
    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items",
      handler: :list_items,
      api_class: RailsNinja::API,
      headers: [
        { name: "X-API-KEY", type: "string", required: true },
        { name: "X-OPTIONAL", type: "integer", required: false }
      ]
    )

    assert_equal 2, endpoint.header_params.size
    assert_equal "X-API-KEY", endpoint.header_params[0][:name]
    assert_equal true, endpoint.header_params[0][:required]
    assert_equal "X-OPTIONAL", endpoint.header_params[1][:name]
    assert_equal false, endpoint.header_params[1][:required]
    assert_equal({ type: "integer" }, endpoint.header_params[1][:schema])
  end

  def test_header_params_default_to_empty
    endpoint = RailsNinja::Endpoint.new(
      verb: :get,
      path: "/items",
      handler: :list_items,
      api_class: RailsNinja::API
    )

    assert_equal [], endpoint.header_params
  end

  def test_class_level_headers_applied_to_endpoint
    api_class = Class.new(RailsNinja::API) do
      headers "X-API-KEY", "X-TENANT-ID"
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/items", handler: :list_items, api_class: api_class
    )

    assert_equal 2, endpoint.header_params.size
    assert_equal "X-API-KEY", endpoint.header_params[0][:name]
    assert_equal "X-TENANT-ID", endpoint.header_params[1][:name]
  end

  def test_class_level_headers_merged_with_endpoint_headers
    api_class = Class.new(RailsNinja::API) do
      headers "X-API-KEY"
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/items", handler: :list_items, api_class: api_class,
      headers: ["X-REQUEST-ID"]
    )

    assert_equal 2, endpoint.header_params.size
    assert_equal "X-API-KEY", endpoint.header_params[0][:name]
    assert_equal "X-REQUEST-ID", endpoint.header_params[1][:name]
  end

  def test_endpoint_headers_override_class_level_headers
    api_class = Class.new(RailsNinja::API) do
      headers({ name: "X-API-KEY", required: true })
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/items", handler: :list_items, api_class: api_class,
      headers: [{ name: "X-API-KEY", required: false }]
    )

    assert_equal 1, endpoint.header_params.size
    assert_equal "X-API-KEY", endpoint.header_params[0][:name]
    assert_equal false, endpoint.header_params[0][:required]
  end

  def test_before_action_with_method_name
    api_class = Class.new(RailsNinja::API) do
      before_action :check_auth

      define_method(:check_auth) do
        RailsNinja::Response.error("Unauthorized", status: 401) unless request.headers["Api-Key"] == "secret"
      end

      define_method(:list_items) { [{ id: 1 }] }
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/items", handler: :list_items, api_class: api_class
    )

    # Without the right header — halted
    env = Rack::MockRequest.env_for("/items", method: "GET")
    req = RailsNinja::Request.new(env, {})
    status, _, body = endpoint.call(api_class.new(req), req)
    assert_equal 401, status
    assert_equal "Unauthorized", MultiJson.load(body.first, symbolize_keys: true)[:error]

    # With the right header — passes through
    env = Rack::MockRequest.env_for("/items", method: "GET", "HTTP_API_KEY" => "secret")
    req = RailsNinja::Request.new(env, {})
    status, _, body = endpoint.call(api_class.new(req), req)
    assert_equal 200, status
  end

  def test_before_action_with_block
    api_class = Class.new(RailsNinja::API) do
      before_action { 403 }

      define_method(:list_items) { [{ id: 1 }] }
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/items", handler: :list_items, api_class: api_class
    )

    env = Rack::MockRequest.env_for("/items", method: "GET")
    req = RailsNinja::Request.new(env, {})
    status, _, _ = endpoint.call(api_class.new(req), req)
    assert_equal 403, status
  end

  def test_before_action_passes_when_nil_returned
    api_class = Class.new(RailsNinja::API) do
      before_action :noop

      define_method(:noop) { nil }
      define_method(:list_items) { { ok: true } }
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/items", handler: :list_items, api_class: api_class
    )

    env = Rack::MockRequest.env_for("/items", method: "GET")
    req = RailsNinja::Request.new(env, {})
    status, _, body = endpoint.call(api_class.new(req), req)
    assert_equal 200, status
    assert_equal true, MultiJson.load(body.first, symbolize_keys: true)[:ok]
  end

  def test_multiple_before_actions_halt_on_first_failure
    api_class = Class.new(RailsNinja::API) do
      before_action :first_check
      before_action :second_check

      define_method(:first_check) { nil }
      define_method(:second_check) { 503 }
      define_method(:list_items) { { ok: true } }
    end

    endpoint = RailsNinja::Endpoint.new(
      verb: :get, path: "/items", handler: :list_items, api_class: api_class
    )

    env = Rack::MockRequest.env_for("/items", method: "GET")
    req = RailsNinja::Request.new(env, {})
    status, _, _ = endpoint.call(api_class.new(req), req)
    assert_equal 503, status
  end
end
