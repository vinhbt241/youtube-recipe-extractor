require "rails_helper"

RSpec.describe DeepseekClient do
  let(:api_key) { "test-key" }

  def ok_response(content)
    double(code: "200", body: { "choices" => [ { "message" => { "content" => content } } ] }.to_json)
  end

  describe "#complete_json" do
    it "posts the model, system/user messages, and JSON format, and returns parsed JSON" do
      sent = nil
      post = lambda do |body|
        sent = JSON.parse(body)
        ok_response('{"title":"Cake","ingredients":["flour"]}')
      end

      result = described_class.new(api_key: api_key, post: post).complete_json(
        system: "You extract recipes.",
        user: "Description and transcript here"
      )

      expect(result).to eq("title" => "Cake", "ingredients" => [ "flour" ])
      expect(sent["model"]).to eq("deepseek-flash")
      expect(sent["messages"].map { |m| m["role"] }).to eq(%w[system user])
      expect(sent.dig("messages", 0, "content")).to eq("You extract recipes.")
      expect(sent.dig("messages", 1, "content")).to eq("Description and transcript here")
      expect(sent["response_format"]).to eq("type" => "json_object")
      expect(sent["stream"]).to be(false)
    end

    it "raises Error on a non-200 response" do
      post = ->(_body) { double(code: "500", body: "boom") }

      expect {
        described_class.new(api_key: api_key, post: post).complete_json(system: "s", user: "u")
      }.to raise_error(DeepseekClient::Error, /500/)
    end

    it "raises Error when the content is not valid JSON" do
      post = ->(_body) { ok_response("not json") }

      expect {
        described_class.new(api_key: api_key, post: post).complete_json(system: "s", user: "u")
      }.to raise_error(DeepseekClient::Error, /invalid JSON/)
    end

    it "raises Error when there is no content" do
      post = ->(_body) { double(code: "200", body: { "choices" => [] }.to_json) }

      expect {
        described_class.new(api_key: api_key, post: post).complete_json(system: "s", user: "u")
      }.to raise_error(DeepseekClient::Error, /no content/)
    end
  end
end
