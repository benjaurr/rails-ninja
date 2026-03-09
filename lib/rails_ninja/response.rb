module RailsNinja
  module Response
    JSON_HEADERS = { "content-type" => "application/json" }.freeze
    HTML_HEADERS = { "content-type" => "text/html" }.freeze

    module_function

    def json(body, status: 200)
      [status, JSON_HEADERS, [MultiJson.dump(body)]]
    end

    def html(body, status: 200)
      [status, HTML_HEADERS, [body]]
    end

    def error(message, status:)
      json({ error: message }, status: status)
    end
  end
end
