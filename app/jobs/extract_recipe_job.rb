class ExtractRecipeJob < ApplicationJob
  queue_as :default

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)
    recipe.update!(status: :processing)

    result = RecipeExtractor.new.call(recipe.url)

    if result.ok
      recipe.update!(result.attributes.merge(status: :done, error_code: nil, error_message: nil))
    else
      recipe.update!(
        status: :failed,
        error_code: result.error_code,
        error_message: result.error_message
      )
    end
  rescue StandardError => e
    Rails.logger.error("Recipe extraction failed for recipe #{recipe_id}: #{e.message}")
    recipe&.update!(status: :failed, error_code: "unknown_error", error_message: e.message)
  end
end
