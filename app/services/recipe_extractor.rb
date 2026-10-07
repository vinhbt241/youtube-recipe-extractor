class RecipeExtractor
  Result = Data.define(:ok, :attributes, :error_code, :error_message)

  SYSTEM_PROMPT = <<~PROMPT.strip
    You are a precise recipe extraction assistant. Given a YouTube video's
    description and its spoken transcript, extract the recipe it demonstrates.
    Respond with ONLY a JSON object using exactly these keys:
    "title" (string), "description" (string or null),
    "ingredients" (array of strings), "instructions" (array of strings, one step each),
    "prep_time_minutes" (integer, 0 if unknown), "cook_time_minutes" (integer, 0 if unknown),
    "total_time_minutes" (integer, 0 if unknown), "servings" (string or null).
    Do not wrap the JSON in markdown fences. If the text does not contain a recipe,
    return "title" as null and empty arrays for ingredients and instructions.
  PROMPT

  def initialize(yt_dlp: YtDlpClient.new, deepseek: DeepseekClient.new)
    @yt_dlp = yt_dlp
    @deepseek = deepseek
  end

  def call(url)
    metadata = @yt_dlp.metadata(url)
    track = select_track(metadata)
    return failure("no_captions", "No captions available for this video") if track.nil?

    raw = @yt_dlp.transcript(url, kind: track[:kind], language: track[:language])
    return failure("no_captions", "No captions available for this video") if raw.blank?

    transcript = TranscriptCleaner.clean(raw)
    data = @deepseek.complete_json(system: SYSTEM_PROMPT, user: user_prompt(metadata, transcript))
    attributes = normalize(data)

    return failure("not_a_recipe", "The video does not appear to contain a recipe") unless valid_recipe?(attributes)

    Result.new(
      ok: true,
      attributes: attributes.merge(
        source: "#{track[:kind]}:#{track[:language]}",
        raw_transcript: transcript
      ),
      error_code: nil,
      error_message: nil
    )
  rescue YtDlpClient::Error => e
    failure("video_unavailable", e.message)
  rescue DeepseekClient::Error => e
    failure("llm_error", e.message)
  end

  private

  def select_track(metadata)
    manual = metadata.manual_languages
    auto = metadata.auto_languages

    return { kind: :manual, language: "en" } if manual.include?("en")
    return { kind: :auto, language: "en" } if auto.include?("en")
    return { kind: :manual, language: manual.first } if manual.any?
    return { kind: :auto, language: auto.first } if auto.any?

    nil
  end

  def user_prompt(metadata, transcript)
    <<~PROMPT.strip
      Video title: #{metadata.title}

      Description:
      #{metadata.description}

      Transcript:
      #{transcript}
    PROMPT
  end

  def normalize(data)
    {
      title: data["title"].presence,
      description: data["description"].presence,
      ingredients: Array(data["ingredients"]).map(&:to_s).reject(&:blank?),
      instructions: Array(data["instructions"]).map(&:to_s).reject(&:blank?),
      prep_time_minutes: data["prep_time_minutes"].to_i,
      cook_time_minutes: data["cook_time_minutes"].to_i,
      total_time_minutes: data["total_time_minutes"].to_i,
      servings: data["servings"].presence&.to_s
    }
  end

  def valid_recipe?(attributes)
    attributes[:title].present? && (attributes[:ingredients].any? || attributes[:instructions].any?)
  end

  def failure(code, message)
    Result.new(ok: false, attributes: nil, error_code: code, error_message: message)
  end
end
