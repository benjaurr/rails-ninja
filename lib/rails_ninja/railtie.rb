module RailsNinja
  class Railtie < ::Rails::Railtie
    initializer "rails_ninja.add_autoload_paths" do |app|
      api_path = Rails.root.join("app", "api")
      if api_path.exist?
        app.config.autoload_paths << api_path.to_s
        app.config.eager_load_paths << api_path.to_s
      end
    end
  end
end
