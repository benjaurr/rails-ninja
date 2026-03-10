require "test_helper"

class ApiTest < Minitest::Test
  def test_endpoint_registration_with_get
    api = Class.new(RailsNinja::API) do
      get "/items"
      def list_items
        []
      end
    end

    assert_equal 1, api._endpoints.size
    endpoint = api._endpoints.first
    assert_equal :get, endpoint.verb
    assert_equal "/items", endpoint.path
    assert_equal :list_items, endpoint.handler
  end

  def test_endpoint_registration_with_post_and_schemas
    item_in = Class.new(RailsNinja::Schema::Base) do
      field :name, String
    end

    item_out = Class.new(RailsNinja::Schema::Base) do
      field :id, Integer
      field :name, String
    end

    api = Class.new(RailsNinja::API)
    api.post "/items", request: item_in, response: item_out
    api.class_eval do
      def create_item
        { id: 1, name: params[:name] }
      end
    end

    assert_equal 1, api._endpoints.size
    endpoint = api._endpoints.first
    assert_equal :post, endpoint.verb
    assert_equal "/items", endpoint.path
    assert endpoint.request_schema
    assert endpoint.response_schema
  end

  def test_multiple_endpoints
    api = Class.new(RailsNinja::API) do
      get "/a"
      def method_a; end

      post "/b"
      def method_b; end

      put "/c"
      def method_c; end

      patch "/d"
      def method_d; end

      delete "/e"
      def method_e; end
    end

    assert_equal 5, api._endpoints.size
    verbs = api._endpoints.map(&:verb)
    assert_equal %i[get post put patch delete], verbs
  end

  def test_regular_methods_not_registered
    api = Class.new(RailsNinja::API) do
      get "/items"
      def list_items; end

      def helper_method; end
    end

    assert_equal 1, api._endpoints.size
  end

  def test_schema_registered_as_constant
    api = Class.new(RailsNinja::API) do
      schema :UserOut do
        field :id, Integer
        field :name, String
      end
    end

    assert api.const_defined?(:UserOut)
    assert_equal 2, api::UserOut._fields.size
  end

  def test_title_and_version
    api = Class.new(RailsNinja::API) do
      title "My API"
      version "2.0"
    end

    assert_equal "My API", api._title
    assert_equal "2.0", api._version
  end

  def test_inherited_api_has_separate_endpoints
    parent = Class.new(RailsNinja::API) do
      get "/parent"
      def parent_method; end
    end

    child = Class.new(parent) do
      get "/child"
      def child_method; end
    end

    assert_equal 1, parent._endpoints.size
    assert_equal 1, child._endpoints.size
  end

  def test_docs_enabled_by_default
    api = Class.new(RailsNinja::API)
    assert api._docs_enabled?
  end

  def test_docs_can_be_disabled
    api = Class.new(RailsNinja::API) do
      docs false
    end
    refute api._docs_enabled?
  end

  def test_docs_disabled_hides_endpoints
    api = Class.new(RailsNinja::API) do
      docs false

      get "/items"
      def list_items
        []
      end
    end

    env = Rack::MockRequest.env_for("/docs", method: "GET")
    status, _, _ = api.call(env)
    assert_equal 404, status

    env = Rack::MockRequest.env_for("/openapi.json", method: "GET")
    status, _, _ = api.call(env)
    assert_equal 404, status
  end

  def test_rack_interface
    api = Class.new(RailsNinja::API) do
      get "/hello"
      def hello
        { message: "world" }
      end
    end

    assert api.respond_to?(:call)
  end

  def test_responds_to_make_response
    api = Class.new(RailsNinja::API)
    assert api.respond_to?(:make_response!)
  end

  def test_responds_to_dispatch
    api = Class.new(RailsNinja::API)
    assert api.respond_to?(:dispatch)
  end
end
