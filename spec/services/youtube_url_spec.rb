require "rails_helper"

RSpec.describe YoutubeUrl do
  describe ".video_id" do
    {
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42" => "dQw4w9WgXcQ",
      "https://www.youtube.com/watch?list=PL123&v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://youtu.be/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://youtu.be/dQw4w9WgXcQ?t=42" => "dQw4w9WgXcQ",
      "https://www.youtube.com/shorts/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/embed/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/live/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "http://youtu.be/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "www.youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://youtu.be/ab-_cdefgh1" => "ab-_cdefgh1"
    }.each do |url, expected_id|
      it "extracts #{expected_id} from #{url}" do
        expect(described_class.video_id(url)).to eq(expected_id)
      end
    end

    [ nil, "", "https://example.com", "https://www.youtube.com/watch?v=short",
     "https://www.youtube.com/watch", "https://youtu.be/", "not a url" ].each do |url|
      it "returns nil for #{url.inspect}" do
        expect(described_class.video_id(url)).to be_nil
      end
    end
  end
end
