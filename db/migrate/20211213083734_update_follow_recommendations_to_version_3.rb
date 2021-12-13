class UpdateFollowRecommendationsToVersion3 < ActiveRecord::Migration[6.1]
  def up
    drop_view :follow_recommendations, materialized: true
    create_view :follow_recommendations, version: 3, materialized: { no_data: true }
    safety_assured { add_index :follow_recommendations, :account_id, unique: true }
  end

  def down
    drop_view :follow_recommendations, materialized: true
    create_view :follow_recommendations, version: 2, materialized: { no_data: true }
    safety_assured { add_index :follow_recommendations, :account_id, unique: true }
  end
end
