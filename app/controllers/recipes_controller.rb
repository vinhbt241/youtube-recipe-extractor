class RecipesController < ApplicationController
  def new
    @recipe = Recipe.new
  end

  def create
    url = params.dig(:recipe, :url).to_s.strip
    video_id = YoutubeUrl.video_id(url)

    if video_id.nil?
      @recipe = Recipe.new(url: url)
      @recipe.errors.add(:url, "is not a valid YouTube URL")
      render :new, status: :unprocessable_content
      return
    end

    @recipe = Recipe.find_by(video_id: video_id)
    return redirect_to recipe_path(@recipe) if @recipe

    @recipe = Recipe.create!(video_id: video_id, url: url)
    ExtractRecipeJob.perform_later(@recipe.id)
    redirect_to recipe_path(@recipe)
  end

  def show
    @recipe = Recipe.find(params[:id])
  end
end
