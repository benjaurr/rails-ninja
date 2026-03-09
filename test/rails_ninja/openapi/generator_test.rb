require "test_helper"

class GeneratorTestApi < RailsNinja::API
  title "Test API"
  version "1.0"

  schema :ItemOut do
    field :id, Integer
    field :name, String
  end

  schema :ItemIn do
    field :name, String
  end

  get "/items", response: [ItemOut]
  def list_items; end

  post "/items", request: ItemIn, response: ItemOut
  def create_item; end

  get "/items/:id", response: ItemOut
  def get_item; end
end

class GeneratorTest < Minitest::Test
  def setup
    router = RailsNinja::Router.new
    router.add_api(GeneratorTestApi)
    @generator = RailsNinja::OpenAPI::Generator.new(router, GeneratorTestApi)
  end

  def test_spec_structure
    spec = @generator.to_hash

    assert_equal "3.0.3", spec[:openapi]
    assert_equal "Test API", spec[:info][:title]
    assert_equal "1.0", spec[:info][:version]
    assert spec[:paths]
    assert spec[:components][:schemas]
  end

  def test_paths_generated
    spec = @generator.to_hash

    assert spec[:paths]["/items"]
    assert spec[:paths]["/items/{id}"]
    assert spec[:paths]["/items"]["get"]
    assert spec[:paths]["/items"]["post"]
    assert spec[:paths]["/items/{id}"]["get"]
  end

  def test_request_body_generated
    spec = @generator.to_hash
    post_op = spec[:paths]["/items"]["post"]

    assert post_op[:requestBody]
    assert post_op[:requestBody][:content]["application/json"]
  end

  def test_response_schema_generated
    spec = @generator.to_hash
    get_op = spec[:paths]["/items"]["get"]

    response = get_op[:responses]["200"]
    assert response[:content]["application/json"]
    schema = response[:content]["application/json"][:schema]
    assert_equal "array", schema[:type]
  end

  def test_path_parameters_generated
    spec = @generator.to_hash
    get_op = spec[:paths]["/items/{id}"]["get"]

    assert get_op[:parameters]
    param = get_op[:parameters].first
    assert_equal "id", param[:name]
    assert_equal "path", param[:in]
    assert param[:required]
  end

  def test_component_schemas_generated
    spec = @generator.to_hash
    schemas = spec[:components][:schemas]

    assert schemas.any?
    assert schemas.size >= 1
  end
end
