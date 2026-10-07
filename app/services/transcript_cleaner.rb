require "cgi"

module TranscriptCleaner
  def self.clean(raw)
    return "" if raw.blank?

    lines = raw.split("\n").filter_map { |line| clean_line(line) }
    dedupe_roll_up(lines).join(" ")
  end

  def self.clean_line(line)
    line = line.strip
    return nil if skip?(line)

    text = line.gsub(/<[^>]*>/, "")
    text = CGI.unescapeHTML(text).gsub(/\u00A0/, " ").gsub(/\s+/, " ").strip
    text.presence
  end

  def self.skip?(line)
    line.empty? ||
      line == "WEBVTT" ||
      line.start_with?("Kind:", "Language:", "NOTE", "STYLE") ||
      line.include?("-->") ||
      line.match?(/\A\d+\z/)
  end

  def self.dedupe_roll_up(lines)
    lines.each_with_index.filter_map do |line, index|
      next_line = lines[index + 1]
      next_line && next_line.downcase.start_with?(line.downcase) ? nil : line
    end
  end

  private_class_method :clean_line, :skip?, :dedupe_roll_up
end
