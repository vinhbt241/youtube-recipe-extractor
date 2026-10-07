require "rails_helper"

RSpec.describe "Recipes", type: :request do
  include ActiveJob::TestHelper

  describe "POST /recipes" do
    it "creates a pending recipe, enqueues extraction, and redirects to show" do
      assert_enqueued_with(job: ExtractRecipeJob) do
        post recipes_path, params: { recipe: { url: "https://youtu.be/dQw4w9WgXcQ" } }
      end

      recipe = Recipe.last
      expect(recipe.video_id).to eq("dQw4w9WgXcQ")
      expect(recipe.status).to eq("pending")
      expect(response).to redirect_to(recipe_path(recipe))
    end

    it "returns the existing recipe without enqueueing for a duplicate URL variant" do
      existing = create(:recipe, video_id: "dQw4w9WgXcQ", url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")

      assert_no_enqueued_jobs do
        post recipes_path, params: { recipe: { url: "https://youtu.be/dQw4w9WgXcQ?t=42" } }
      end

      expect(Recipe.count).to eq(1)
      expect(response).to redirect_to(recipe_path(existing))
    end

    it "re-renders the form without creating a recipe or enqueueing for an invalid URL" do
      assert_no_enqueued_jobs do
        post recipes_path, params: { recipe: { url: "https://example.com" } }
      end

      expect(Recipe.count).to eq(0)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("not a valid YouTube URL")
    end
  end

  describe "GET /recipes/:id" do
    it "renders the recipe" do
      recipe = create(:recipe, title: "Cake", status: "done")

      get recipe_path(recipe)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cake")
    end
  end
end
