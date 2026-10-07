FactoryBot.define do
  factory :recipe do
    sequence(:video_id) { |n| "video-#{n}" }
    url { "https://www.youtube.com/watch?v=#{video_id}" }
  end
end
