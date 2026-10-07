require "rails_helper"

RSpec.describe Recipe, type: :model do
  subject(:recipe) { build(:recipe) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:video_id) }
    it { is_expected.to validate_uniqueness_of(:video_id) }
    it { is_expected.to validate_presence_of(:url) }
  end

  describe "status" do
    it "defaults to pending" do
      expect(Recipe.new.status).to eq("pending")
    end

    it "rejects an unknown status" do
      expect { build(:recipe, status: "bogus") }.to raise_error(ArgumentError)
    end
  end
end
