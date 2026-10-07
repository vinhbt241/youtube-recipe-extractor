require "json"
require "net/http"
require "uri"

class DeepseekClient
  BASE_URL = "https://api.deepseek.com/chat/completions".freeze

  def initialize(api_key: ENV.fetch("DEEPSEEK_API_KEY"), post: method(:http_post))
    @api_key = api_key
    @post = post
  end

  def complete_json(system:, user:)
    body = {
      model: "deepseek-flash",
      messages: [
        { role: "system", content: system },
        { role: "user", content: user }
      ],
      response_format: { type: "json_object" },
      stream: false
    }.to_json

    response = @post.call(body)
    raise Error, "DeepSeek API error (#{response.code}): #{response.body}" unless response.code.to_i == 200

    parsed = JSON.parse(response.body)
    content = parsed.dig("choices", 0, "message", "content")
    raise Error, "DeepSeek returned no content" if content.blank?

    JSON.parse(content)
  rescue JSON::ParserError => e
    raise Error, "DeepSeek returned invalid JSON: #{e.message}"
  end

  def http_post(body)
    uri = URI(BASE_URL)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{@api_key}"
    request.body = body

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
  end

  class Error < StandardError; end
end
