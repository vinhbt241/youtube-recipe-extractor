require "json"
require "open3"
require "tmpdir"

class YtDlpClient
  Metadata = Data.define(:video_id, :title, :description, :manual_languages, :auto_languages)

  def initialize(runner: self.class.method(:system_runner))
    @runner = runner
  end

  def metadata(url)
    out, err, status = @runner.call([ "--dump-json", "--no-warnings", url ])
    raise Error, "yt-dlp failed: #{err}" unless status.success?

    json = JSON.parse(out)
    Metadata.new(
      video_id: json.fetch("id"),
      title: json.fetch("title"),
      description: json.fetch("description", ""),
      manual_languages: (json["subtitles"] || {}).keys,
      auto_languages: (json["automatic_captions"] || {}).keys
    )
  rescue JSON::ParserError => e
    raise Error, "yt-dlp returned invalid JSON: #{e.message}"
  end

  def transcript(url, kind:, language:)
    flag = kind == :manual ? "--write-subs" : "--write-auto-subs"

    Dir.mktmpdir do |dir|
      _out, err, status = @runner.call(
        [ "--skip-download", flag, "--sub-langs", language, "--sub-format", "vtt",
         "-o", File.join(dir, "%(id)s"), url ]
      )
      raise Error, "yt-dlp subtitle download failed: #{err}" unless status.success?

      file = Dir.glob(File.join(dir, "*.vtt")).first
      file && File.read(file)
    end
  end

  def self.system_runner(args)
    Open3.capture3("yt-dlp", *args)
  end

  class Error < StandardError; end
end
