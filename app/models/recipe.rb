class Recipe < ApplicationRecord
  enum :status, {
    pending: "pending",
    processing: "processing",
    done: "done",
    failed: "failed"
  }, default: :pending

  validates :video_id, presence: true, uniqueness: true
  validates :url, presence: true
end
