require "rails_helper"

RSpec.describe YtDlpClient do
  let(:status_ok) { double(success?: true) }
  let(:status_fail) { double(success?: false) }

  describe "#metadata" do
    it "parses id, title, description, and caption languages from --dump-json" do
      json = {
        "id" => "dQw4w9WgXcQ",
        "title" => "The Best Chocolate Cake",
        "description" => "Ingredients\n- flour",
        "subtitles" => { "en" => [ { "ext" => "vtt" } ], "vi" => [ { "ext" => "vtt" } ] },
        "automatic_captions" => { "en" => [ { "ext" => "vtt" } ], "es" => [ { "ext" => "json3" } ] }
      }.to_json

      invoked = nil
      runner = lambda do |args|
        invoked = args
        [ json, "", status_ok ]
      end

      metadata = described_class.new(runner: runner).metadata("https://youtu.be/dQw4w9WgXcQ")

      expect(metadata.video_id).to eq("dQw4w9WgXcQ")
      expect(metadata.title).to eq("The Best Chocolate Cake")
      expect(metadata.description).to eq("Ingredients\n- flour")
      expect(metadata.manual_languages).to eq(%w[en vi])
      expect(metadata.auto_languages).to eq(%w[en es])
      expect(invoked).to eq([ "--dump-json", "--no-warnings", "https://youtu.be/dQw4w9WgXcQ" ])
    end

    it "defaults missing description and caption lists to empty" do
      json = { "id" => "abc", "title" => "T" }.to_json
      runner = ->(_args) { [ json, "", status_ok ] }

      metadata = described_class.new(runner: runner).metadata("url")

      expect(metadata.description).to eq("")
      expect(metadata.manual_languages).to eq([])
      expect(metadata.auto_languages).to eq([])
    end

    it "raises Error when yt-dlp exits non-zero" do
      runner = ->(_args) { [ "", "ERROR: Video unavailable", status_fail ] }

      expect { described_class.new(runner: runner).metadata("url") }
        .to raise_error(YtDlpClient::Error, /Video unavailable/)
    end
  end

  describe "#transcript" do
    it "runs --write-subs for a manual track and returns the written VTT" do
      invoked = nil
      runner = lambda do |args|
        invoked = args
        output_dir = File.dirname(args[args.index("-o") + 1])
        File.write(File.join(output_dir, "abc.en.vtt"), "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nhello\n")
        [ "", "", status_ok ]
      end

      text = described_class.new(runner: runner).transcript("url", kind: :manual, language: "en")

      expect(text).to eq("WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nhello\n")
      expect(invoked).to include("--write-subs", "--sub-langs", "en", "--sub-format", "vtt", "--skip-download")
    end

    it "runs --write-auto-subs for an auto track" do
      invoked = nil
      runner = lambda do |args|
        invoked = args
        output_dir = File.dirname(args[args.index("-o") + 1])
        File.write(File.join(output_dir, "abc.en.vtt"), "WEBVTT\n")
        [ "", "", status_ok ]
      end

      described_class.new(runner: runner).transcript("url", kind: :auto, language: "en")

      expect(invoked).to include("--write-auto-subs")
      expect(invoked).not_to include("--write-subs")
    end

    it "returns nil when no caption file was written" do
      runner = ->(_args) { [ "", "", status_ok ] }

      expect(described_class.new(runner: runner).transcript("url", kind: :auto, language: "en")).to be_nil
    end

    it "raises Error when the subtitle download exits non-zero" do
      runner = ->(_args) { [ "", "boom", status_fail ] }

      expect { described_class.new(runner: runner).transcript("url", kind: :manual, language: "en") }
        .to raise_error(YtDlpClient::Error)
    end
  end
end
