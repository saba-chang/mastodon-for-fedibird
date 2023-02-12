require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddSilenceModeToAccount < ActiveRecord::Migration[6.1]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured { add_column_with_default :accounts, :silence_mode, :integer, default: 0, allow_null: false }
  end

  def down
    remove_column :accounts, :silence_mode
  end
end
