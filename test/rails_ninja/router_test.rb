require "test_helper"

class RouterTest < Minitest::Test
  def setup
    @api = Class.new(RailsNinja::API) do
      get "/items"
      def list_items
        []
      end

      get "/items/:id"
      def get_item
        {}
      end

      post "/items"
      def create_item
        {}
      end
    end

    @router = RailsNinja::Router.new
    @router.add_api(@api)
  end

  def test_match_simple_get
    endpoint, params = @router.match("GET", "/items")

    assert endpoint
    assert_equal :list_items, endpoint.handler
    assert_empty params
  end

  def test_match_with_path_params
    endpoint, params = @router.match("GET", "/items/42")

    assert endpoint
    assert_equal :get_item, endpoint.handler
    assert_equal "42", params["id"]
  end

  def test_match_post
    endpoint, params = @router.match("POST", "/items")

    assert endpoint
    assert_equal :create_item, endpoint.handler
  end

  def test_no_match
    result = @router.match("DELETE", "/items")

    assert_nil result
  end

  def test_no_match_wrong_path
    result = @router.match("GET", "/nonexistent")

    assert_nil result
  end

  def test_mount_with_prefix
    sub_api = Class.new(RailsNinja::API) do
      get "/list"
      def list; end
    end

    router = RailsNinja::Router.new
    router.add_api(sub_api, prefix: "/api/v1")

    endpoint, _ = router.match("GET", "/api/v1/list")
    assert endpoint
    assert_equal :list, endpoint.handler
  end
end
