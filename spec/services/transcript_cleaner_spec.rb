require "rails_helper"

RSpec.describe TranscriptCleaner do
  describe ".clean" do
    it "strips VTT headers, timestamps, tags, and roll-up duplicates" do
      raw = <<~VTT
        WEBVTT
        Kind: captions
        Language: en

        00:00:00.320 --> 00:00:18.790 align:start position:0%
        [Music]

        00:00:18.790 --> 00:00:18.800 align:start position:0%
        We're<00:00:19.039><c> no</c> strangers

        00:00:21.790 --> 00:00:21.800 align:start position:0%
        We're no strangers to

        00:00:21.800 --> 00:00:25.950 align:start position:0%
        We're no strangers to love
      VTT

      expect(described_class.clean(raw)).to eq("[Music] We're no strangers to love")
    end

    it "parses SRT, unescapes entities, and keeps complete cues" do
      raw = <<~SRT
        1
        00:00:00,320 --> 00:00:18,790
        [Music]

        2
        00:00:18,790 --> 00:00:18,800
        Add the flour &amp; sugar
      SRT

      expect(described_class.clean(raw)).to eq("[Music] Add the flour & sugar")
    end

    it "collapses consecutive duplicate cues" do
      raw = <<~VTT
        WEBVTT

        00:00:01.000 --> 00:00:02.000
        hello

        00:00:02.000 --> 00:00:03.000
        hello

        00:00:03.000 --> 00:00:04.000
        world
      VTT

      expect(described_class.clean(raw)).to eq("hello world")
    end

    it "collapses inner whitespace and drops empty cues" do
      raw = <<~VTT
        WEBVTT

        00:00:01.000 --> 00:00:02.000
          <c>Mix</c>   well
      VTT

      expect(described_class.clean(raw)).to eq("Mix well")
    end

    it "returns an empty string for blank input" do
      expect(described_class.clean(nil)).to eq("")
      expect(described_class.clean("")).to eq("")
    end
  end
end
