require_relative "../lib/rails_ninja"

class ItemOut < RailsNinja::Schema::Base
  field :id, Integer
  field :name, String
  field :price, Float
end

class ItemIn < RailsNinja::Schema::Base
  field :name, String
  field :price, Float
end

class UserOut < RailsNinja::Schema::Base
  field :id, Integer
  field :name, String
  field :email, String
end

class UserIn < RailsNinja::Schema::Base
  field :name, String
  field :email, String
end

class PublicApi < RailsNinja::API
  title "Public API"
  version "1.0"

  get "/items", response: [ItemOut]
  def list_items
    [
      { id: 1, name: "Widget", price: 9.99 },
      { id: 2, name: "Gadget", price: 24.99 }
    ]
  end

  get "/items/:id", response: ItemOut
  def get_item
    { id: params[:id].to_i, name: "Widget", price: 9.99 }
  end

  post "/items", request: ItemIn, response: ItemOut
  def create_item
    { id: 3, name: params[:name], price: params[:price] }
  end
end

class AdminApi < RailsNinja::API
  title "Admin API"
  version "1.0"

  get "/users", response: [UserOut]
  def list_users
    [
      { id: 1, name: "Alice", email: "alice@example.com" },
      { id: 2, name: "Bob", email: "bob@example.com" }
    ]
  end

  post "/users", request: UserIn, response: UserOut
  def create_user
    { id: 3, name: params[:name], email: params[:email] }
  end

  delete "/users/:id"
  def delete_user
    { deleted: true }
  end
end

app = Rack::Builder.new do
  map "/api" do
    run PublicApi
  end

  map "/admin" do
    run AdminApi
  end

  map "/" do
    run ->(env) {
      [200, { "content-type" => "text/html" }, [<<~HTML]]
        <!DOCTYPE html>
        <html>
        <head><title>Rails Ninja Demo</title></head>
        <body style="font-family: sans-serif; max-width: 600px; margin: 80px auto;">
          <h1>Rails Ninja Demo</h1>
          <ul>
            <li><a href="/api/docs">Public API Docs</a></li>
            <li><a href="/admin/docs">Admin API Docs</a></li>
          </ul>
        </body>
        </html>
      HTML
    }
  end
end

run app
