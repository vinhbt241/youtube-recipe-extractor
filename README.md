# YouTube Recipe Extractor

Paste a YouTube cooking-video URL and get the recipe: ingredients, steps, and times,
extracted from the video's description and captions.

## How it works

1. Normalize the URL to a `video_id` (dedup key — `youtu.be/x` and `watch?v=x` are the same recipe).
2. If the recipe already exists, return it; otherwise create a `pending` recipe and enqueue a job.
3. The job runs `yt-dlp` to fetch the video metadata (title + description) and the caption track
   (manual captions preferred, auto-generated as fallback; English preferred).
4. The transcript is cleaned, then `deepseek-flash` extracts the recipe as JSON.
5. The recipe is saved and the show page polls until it's `done` or `failed`.

## Requirements

- Ruby 4.0.6 (see `.ruby-version`)
- PostgreSQL
- `yt-dlp` on `PATH` (macOS: `brew install yt-dlp`; otherwise `pip install yt-dlp` or the standalone binary)
- `DEEPSEEK_API_KEY` in the environment (DeepSeek API: https://api.deepseek.com)

## Setup

```sh
bundle install
bin/rails db:prepare
DEEPSEEK_API_KEY=sk-... bin/dev
```

Open http://localhost:3000 and paste a video URL.

## Background jobs

- **Development** uses Rails' in-process `:async` adapter — no worker process needed.
- **Production** uses Solid Queue (`bin/jobs`), configured in `config/environments/production.rb`.

## Tests

```sh
bundle exec rspec
```

The extraction pipeline is fully stubbed in specs (no network or API key required).
