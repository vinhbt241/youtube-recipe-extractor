require "rails_helper"

RSpec.describe ExtractRecipeJob, type: :job do
  let(:recipe) { create(:recipe) }

  it "marks the recipe done with extracted attributes on success" do
    result = RecipeExtractor::Result.new(
      ok: true,
      attributes: {
        title: "Cake",
        description: "Rich",
        ingredients: [ "flour" ],
        instructions: [ "Mix" ],
        prep_time_minutes: 10,
        cook_time_minutes: 20,
        total_time_minutes: 30,
        servings: "4",
        source: "manual:en",
        raw_transcript: "Add flour"
      },
      error_code: nil,
      error_message: nil
    )
    extractor = instance_double(RecipeExtractor, call: result)
    allow(RecipeExtractor).to receive(:new).and_return(extractor)

    described_class.perform_now(recipe.id)

    recipe.reload
    expect(recipe.status).to eq("done")
    expect(recipe.title).to eq("Cake")
    expect(recipe.ingredients).to eq([ "flour" ])
    expect(recipe.source).to eq("manual:en")
    expect(recipe.error_code).to be_nil
  end

  it "marks the recipe failed with the extractor's error code on failure" do
    result = RecipeExtractor::Result.new(
      ok: false, attributes: nil,
      error_code: "no_captions", error_message: "No captions available for this video"
    )
    extractor = instance_double(RecipeExtractor, call: result)
    allow(RecipeExtractor).to receive(:new).and_return(extractor)

    described_class.perform_now(recipe.id)

    recipe.reload
    expect(recipe.status).to eq("failed")
    expect(recipe.error_code).to eq("no_captions")
    expect(recipe.error_message).to eq("No captions available for this video")
  end

  it "marks the recipe failed with unknown_error on an unexpected exception" do
    allow(RecipeExtractor).to receive(:new).and_raise(StandardError, "boom")

    described_class.perform_now(recipe.id)

    recipe.reload
    expect(recipe.status).to eq("failed")
    expect(recipe.error_code).to eq("unknown_error")
    expect(recipe.error_message).to eq("boom")
  end
end
