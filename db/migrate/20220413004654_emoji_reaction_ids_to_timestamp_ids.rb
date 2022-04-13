class EmojiReactionIdsToTimestampIds < ActiveRecord::Migration[6.1]
  def up
    # Set up the accounts.id column to use our timestamp-based IDs.
    safety_assured do
      execute("ALTER TABLE emoji_reactions ALTER COLUMN id SET DEFAULT timestamp_id('emoji_reactions')")
    end

    # Make sure we have a sequence to use.
    Mastodon::Snowflake.ensure_id_sequences_exist
  end

  def down
    execute("LOCK emoji_reactions")
    execute("SELECT setval('emoji_reactions_id_seq', (SELECT MAX(id) FROM emoji_reactions))")
    execute("ALTER TABLE emoji_reactions ALTER COLUMN id SET DEFAULT nextval('emoji_reactions_id_seq')")
  end
end
