# Rails Ninja

A lightweight API framework for Ruby/Rails inspired by [Django Ninja](https://django-ninja.dev). Define endpoints with a decorator-like DSL, validate requests with schemas, and get automatic OpenAPI documentation.

## Installation

Add to your Gemfile:

```ruby
gem "rails_ninja"
```

## Usage

### Defining an API

```ruby
class UsersApi < RailsNinja::API
  title "Users API"
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
    User.all
  end

  get "/users/:id", response: UserOut
  def get_user
    User.find(params[:id])
  end

  post "/users", request: UserIn, response: UserOut
  def create_user
    User.create!(params)
  end
end
```

### Mounting in Rails

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount UsersApi => "/api"
end
```

Place your API classes in `app/api/` and they will be autoloaded.

### Composing APIs

```ruby
class ApplicationApi < RailsNinja::API
  title "My Service"
  version "1.0"

  mount UsersApi, prefix: "/users"
  mount PostsApi, prefix: "/posts"
end

# config/routes.rb
mount ApplicationApi => "/api"
```

### Schemas

Schemas handle both request validation and response serialization.

```ruby
schema :ItemIn do
  field :name, String
  field :price, Float
  field :category, String, required: false, default: "general"
end
```

Fields are required by default. Incoming data is coerced to the declared type when possible. Invalid requests return a `422` with error details.

You can also define schemas as standalone classes:

```ruby
class ItemOut < RailsNinja::Schema::Base
  field :id, Integer
  field :name, String
  field :price, Float
end
```

### OpenAPI Documentation

Every mounted API automatically serves:

- `GET /openapi.json` -- OpenAPI 3.0 spec
- `GET /docs` -- Swagger UI

## Dependencies

- `rack`
- `multi_json`
- `mustermann`

## License

MIT
