require "rails_helper"

RSpec.describe RecipeExtractor do
  let(:yt_dlp) { instance_double(YtDlpClient) }
  let(:deepseek) { instance_double(DeepseekClient) }
  let(:extractor) { described_class.new(yt_dlp: yt_dlp, deepseek: deepseek) }

  def metadata(manual: [], auto: [])
    YtDlpClient::Metadata.new(
      video_id: "dQw4w9WgXcQ",
      title: "Video Title",
      description: "A lovely cake",
      manual_languages: manual,
      auto_languages: auto
    )
  end

  describe "#call" do
    it "extracts and normalizes a recipe, preferring the manual English track" do
      allow(yt_dlp).to receive(:metadata).and_return(metadata(manual: %w[en vi], auto: %w[en]))
      allow(yt_dlp).to receive(:transcript)
        .with(anything, kind: :manual, language: "en")
        .and_return("WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nAdd <c>flour</c>")
      allow(deepseek).to receive(:complete_json).and_return(
        "title" => "Chocolate Cake",
        "description" => "Rich cake",
        "ingredients" => %w[flour sugar],
        "instructions" => %w[Mix Bake],
        "prep_time_minutes" => 15,
        "cook_time_minutes" => 30,
        "total_time_minutes" => 45,
        "servings" => "8"
      )

      result = extractor.call("https://youtu.be/dQw4w9WgXcQ")

      expect(result.ok).to be(true)
      expect(result.attributes).to include(
        title: "Chocolate Cake",
        description: "Rich cake",
        ingredients: %w[flour sugar],
        instructions: %w[Mix Bake],
        prep_time_minutes: 15,
        cook_time_minutes: 30,
        total_time_minutes: 45,
        servings: "8",
        source: "manual:en",
        raw_transcript: "Add flour"
      )
    end

    it "falls back to auto English when no manual English track exists" do
      allow(yt_dlp).to receive(:metadata).and_return(metadata(manual: %w[vi], auto: %w[vi en]))
      allow(yt_dlp).to receive(:transcript)
        .with(anything, kind: :auto, language: "en")
        .and_return("WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nMix well")
      allow(deepseek).to receive(:complete_json).and_return(
        "title" => "Cake", "ingredients" => [ "flour" ], "instructions" => [ "Mix" ]
      )

      result = extractor.call("url")

      expect(result.ok).to be(true)
      expect(result.attributes[:source]).to eq("auto:en")
    end

    it "fails with no_captions when the video has no caption tracks" do
      allow(yt_dlp).to receive(:metadata).and_return(metadata(manual: [], auto: []))

      result = extractor.call("url")

      expect(result.ok).to be(false)
      expect(result.error_code).to eq("no_captions")
    end

    it "fails with no_captions when the transcript download yields nothing" do
      allow(yt_dlp).to receive(:metadata).and_return(metadata(manual: %w[en]))
      allow(yt_dlp).to receive(:transcript).and_return(nil)

      result = extractor.call("url")

      expect(result.ok).to be(false)
      expect(result.error_code).to eq("no_captions")
    end

    it "fails with not_a_recipe when the LLM returns no title and no content" do
      allow(yt_dlp).to receive(:metadata).and_return(metadata(manual: %w[en]))
      allow(yt_dlp).to receive(:transcript).and_return("WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nhello")
      allow(deepseek).to receive(:complete_json).and_return(
        "title" => nil, "description" => nil, "ingredients" => [], "instructions" => []
      )

      result = extractor.call("url")

      expect(result.ok).to be(false)
      expect(result.error_code).to eq("not_a_recipe")
    end

    it "fails with llm_error when DeepSeek raises" do
      allow(yt_dlp).to receive(:metadata).and_return(metadata(manual: %w[en]))
      allow(yt_dlp).to receive(:transcript).and_return("WEBVTT\n")
      allow(deepseek).to receive(:complete_json).and_raise(DeepseekClient::Error, "boom")

      result = extractor.call("url")

      expect(result.ok).to be(false)
      expect(result.error_code).to eq("llm_error")
    end

    it "fails with video_unavailable when yt-dlp raises" do
      allow(yt_dlp).to receive(:metadata).and_raise(YtDlpClient::Error, "Video unavailable")

      result = extractor.call("url")

      expect(result.ok).to be(false)
      expect(result.error_code).to eq("video_unavailable")
    end
  end
end
