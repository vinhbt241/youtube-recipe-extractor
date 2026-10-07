class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :video_id, null: false
      t.string :url, null: false
      t.string :title
      t.text :description
      t.jsonb :ingredients, null: false, default: []
      t.jsonb :instructions, null: false, default: []
      t.integer :prep_time_minutes
      t.integer :cook_time_minutes
      t.integer :total_time_minutes
      t.string :servings
      t.string :status, null: false, default: "pending"
      t.string :error_code
      t.string :error_message
      t.text :raw_transcript
      t.string :source

      t.timestamps
    end

    add_index :recipes, :video_id, unique: true
  end
end
