require "test_helper"

class PublicApi < RailsNinja::API
  title "Public API"
  version "1.0"

  schema :ProductOut do
    field :id, Integer
    field :name, String
  end

  get "/products", response: [ProductOut]
  def list_products
    [{ id: 1, name: "Widget" }]
  end
end

class AdminApi < RailsNinja::API
  title "Admin API"
  version "2.0"

  schema :SettingOut do
    field :key, String
    field :value, String
  end

  get "/settings", response: [SettingOut]
  def list_settings
    [{ key: "mode", value: "production" }]
  end
end

class MultiApiTest < Minitest::Test
  include Rack::Test::Methods

  def test_public_api_serves_its_endpoints
    with_app(PublicApi) do
      get "/products"
      assert_equal 200, last_response.status
      body = MultiJson.load(last_response.body, symbolize_keys: true)
      assert_equal "Widget", body[0][:name]
    end
  end

  def test_admin_api_serves_its_endpoints
    with_app(AdminApi) do
      get "/settings"
      assert_equal 200, last_response.status
      body = MultiJson.load(last_response.body, symbolize_keys: true)
      assert_equal "mode", body[0][:key]
    end
  end

  def test_public_api_does_not_have_admin_routes
    with_app(PublicApi) do
      get "/settings"
      assert_equal 404, last_response.status
    end
  end

  def test_admin_api_does_not_have_public_routes
    with_app(AdminApi) do
      get "/products"
      assert_equal 404, last_response.status
    end
  end

  def test_public_api_openapi_spec
    with_app(PublicApi) do
      get "/openapi.json"
      spec = MultiJson.load(last_response.body)
      assert_equal "Public API", spec["info"]["title"]
      assert_equal "1.0", spec["info"]["version"]
      assert spec["paths"]["/products"]
      refute spec["paths"]["/settings"]
    end
  end

  def test_admin_api_openapi_spec
    with_app(AdminApi) do
      get "/openapi.json"
      spec = MultiJson.load(last_response.body)
      assert_equal "Admin API", spec["info"]["title"]
      assert_equal "2.0", spec["info"]["version"]
      assert spec["paths"]["/settings"]
      refute spec["paths"]["/products"]
    end
  end

  def test_each_api_has_its_own_docs
    with_app(PublicApi) do
      get "/docs"
      assert_equal 200, last_response.status
      assert_includes last_response.body, "swagger-ui"
    end

    with_app(AdminApi) do
      get "/docs"
      assert_equal 200, last_response.status
      assert_includes last_response.body, "swagger-ui"
    end
  end

  private

  def with_app(app_class)
    @current_app = app_class
    yield
  ensure
    @current_app = nil
  end

  def app
    @current_app
  end
end
