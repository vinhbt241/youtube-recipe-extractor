module YoutubeUrl
  ID = "[A-Za-z0-9_-]{11}".freeze

  PATTERNS = [
    %r{\A(?:https?://)?(?:www\.)?youtube\.com/watch\?(?:[^#]*&)?v=(#{ID})(?:&|#|\z)},
    %r{\A(?:https?://)?(?:www\.)?youtu\.be/(#{ID})(?:[?#]|\z)},
    %r{\A(?:https?://)?(?:www\.)?youtube\.com/(?:shorts|embed|live)/(#{ID})(?:[?#]|\z)}
  ].freeze

  module_function

  def video_id(url)
    return nil if url.blank?

    stripped = url.strip
    PATTERNS.each do |pattern|
      match = pattern.match(stripped)
      return match[1] if match
    end

    nil
  end
end
