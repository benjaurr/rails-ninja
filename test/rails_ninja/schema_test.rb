require "test_helper"

class SchemaTest < Minitest::Test
  def setup
    @schema = Class.new(RailsNinja::Schema::Base) do
      field :name, String
      field :email, String
      field :age, Integer
    end
  end

  def test_field_registration
    assert_equal 3, @schema._fields.size
    assert_equal :name, @schema._fields[:name].name
    assert_equal String, @schema._fields[:name].type
  end

  def test_validate_valid_data
    coerced, errors = @schema.validate({ name: "Alice", email: "alice@example.com", age: 30 })

    assert_empty errors
    assert_equal "Alice", coerced[:name]
    assert_equal 30, coerced[:age]
  end

  def test_validate_missing_required_field
    _, errors = @schema.validate({ name: "Alice" })

    assert_includes errors, "email is required"
    assert_includes errors, "age is required"
  end

  def test_validate_coerces_string_to_integer
    coerced, errors = @schema.validate({ name: "Alice", email: "a@b.com", age: "25" })

    assert_empty errors
    assert_equal 25, coerced[:age]
  end

  def test_validate_optional_field
    schema = Class.new(RailsNinja::Schema::Base) do
      field :name, String
      field :nickname, String, required: false
    end

    coerced, errors = schema.validate({ name: "Alice" })

    assert_empty errors
    assert_equal "Alice", coerced[:name]
    refute coerced.key?(:nickname)
  end

  def test_validate_default_value
    schema = Class.new(RailsNinja::Schema::Base) do
      field :name, String
      field :role, String, required: false, default: "user"
    end

    coerced, errors = schema.validate({ name: "Alice" })

    assert_empty errors
    assert_equal "user", coerced[:role]
  end

  def test_serialize_from_hash
    result = @schema.serialize({ name: "Alice", email: "a@b.com", age: 30 })

    assert_equal({ name: "Alice", email: "a@b.com", age: 30 }, result)
  end

  def test_serialize_from_object
    user = Struct.new(:name, :email, :age).new("Alice", "a@b.com", 30)
    result = @schema.serialize(user)

    assert_equal({ name: "Alice", email: "a@b.com", age: 30 }, result)
  end

  def test_serialize_many
    users = [
      { name: "Alice", email: "a@b.com", age: 30 },
      { name: "Bob", email: "b@b.com", age: 25 }
    ]

    result = @schema.serialize_many(users)

    assert_equal 2, result.size
    assert_equal "Alice", result[0][:name]
    assert_equal "Bob", result[1][:name]
  end

  def test_inherited_fields
    child = Class.new(@schema) do
      field :role, String
    end

    assert_equal 4, child._fields.size
    assert_equal 3, @schema._fields.size
  end
end
