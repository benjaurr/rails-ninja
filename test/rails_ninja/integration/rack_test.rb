require "test_helper"

UserData = Struct.new(:id, :name, :email)

USERS = [
  UserData.new(1, "Alice", "alice@example.com"),
  UserData.new(2, "Bob", "bob@example.com")
]

class TestApi < RailsNinja::API
  title "Test API"
  version "1.0"

  schema :UserOut do
    field :id, Integer
    field :name, String
    field :email, String
  end

  schema :UserIn do
    field :name, String
    field :email, String
  end

  get "/users", response: [UserOut]
  def list_users
    USERS
  end

  get "/users/:id", response: UserOut
  def get_user
    USERS.find { |u| u.id == params[:id].to_i }
  end

  post "/users", request: UserIn, response: UserOut
  def create_user
    UserData.new(3, params[:name], params[:email])
  end

  get "/hello"
  def hello
    { message: "world" }
  end
end

class RackIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TestApi
  end

  def test_get_list
    get "/users"

    assert_equal 200, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal 2, body.size
    assert_equal "Alice", body[0][:name]
  end

  def test_get_with_path_param
    get "/users/1"

    assert_equal 200, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal 1, body[:id]
    assert_equal "Alice", body[:name]
  end

  def test_post_with_body
    post "/users",
      MultiJson.dump({ name: "Charlie", email: "charlie@example.com" }),
      { "CONTENT_TYPE" => "application/json" }

    assert_equal 200, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal "Charlie", body[:name]
    assert_equal 3, body[:id]
  end

  def test_post_validation_error
    post "/users",
      MultiJson.dump({ name: "Charlie" }),
      { "CONTENT_TYPE" => "application/json" }

    assert_equal 422, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert body[:errors]
  end

  def test_get_without_schema
    get "/hello"

    assert_equal 200, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal "world", body[:message]
  end

  def test_not_found
    get "/nonexistent"

    assert_equal 404, last_response.status
  end

  def test_openapi_spec
    get "/openapi.json"

    assert_equal 200, last_response.status
    spec = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal "3.0.3", spec[:openapi]
    assert_equal "Test API", spec[:info][:title]
    assert spec[:paths]
  end

  def test_swagger_ui
    get "/docs"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "swagger-ui"
  end
end
