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
end
