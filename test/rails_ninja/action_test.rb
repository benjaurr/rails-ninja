require "test_helper"

class ListItems < RailsNinja::Action
  schema :ItemOut do
    field :id, Integer
    field :name, String
  end

  get "/items", response: [ItemOut]
  def handle
    [{ id: 1, name: "Widget" }, { id: 2, name: "Gadget" }]
  end
end

class CreateItem < RailsNinja::Action
  schema :ItemIn do
    field :name, String
  end

  schema :ItemCreated do
    field :id, Integer
    field :name, String
  end

  post "/items", request: ItemIn, response: ItemCreated
  def handle
    { id: 3, name: params[:name] }
  end
end

class GetItem < RailsNinja::Action
  get "/items/:id"
  def handle
    { id: params[:id].to_i, name: "Widget" }
  end
end

class ActionDemoApi < RailsNinja::API
  title "Action Demo"
  version "1.0"

  action ListItems
  action CreateItem
  action GetItem
end

class ActionTest < Minitest::Test
  include Rack::Test::Methods

  def app
    ActionDemoApi
  end

  def test_action_registers_endpoint
    assert_equal 1, ListItems._endpoints.size
    ep = ListItems._endpoints.first
    assert_equal :get, ep.verb
    assert_equal "/items", ep.path
    assert_equal :handle, ep.handler
  end

  def test_api_pulls_in_action_endpoints
    assert_equal 3, ActionDemoApi._endpoints.size
    verbs = ActionDemoApi._endpoints.map(&:verb)
    assert_includes verbs, :get
    assert_includes verbs, :post
  end

  def test_get_action_endpoint
    get "/items"

    assert_equal 200, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal 2, body.size
    assert_equal "Widget", body[0][:name]
  end

  def test_post_action_endpoint
    post "/items",
      MultiJson.dump({ name: "Sprocket" }),
      { "CONTENT_TYPE" => "application/json" }

    assert_equal 200, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal "Sprocket", body[:name]
    assert_equal 3, body[:id]
  end

  def test_post_action_validates_request
    post "/items",
      MultiJson.dump({}),
      { "CONTENT_TYPE" => "application/json" }

    assert_equal 422, last_response.status
  end

  def test_action_with_path_params
    get "/items/7"

    assert_equal 200, last_response.status
    body = MultiJson.load(last_response.body, symbolize_keys: true)
    assert_equal 7, body[:id]
  end

  def test_action_schemas_dont_collide
    assert ListItems.const_defined?(:ItemOut)
    assert CreateItem.const_defined?(:ItemIn)
    assert CreateItem.const_defined?(:ItemCreated)
    refute ListItems.const_defined?(:ItemIn)
  end

  def test_openapi_includes_action_endpoints
    get "/openapi.json"

    spec = MultiJson.load(last_response.body)
    assert spec["paths"]["/items"]
    assert spec["paths"]["/items"]["get"]
    assert spec["paths"]["/items"]["post"]
    assert spec["paths"]["/items/{id}"]
  end
end
