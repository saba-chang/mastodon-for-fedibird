# frozen_string_literal: true

class EmojiReactionValidator < ActiveModel::Validator
  SUPPORTED_EMOJIS = Oj.load(File.read(Rails.root.join('app', 'javascript', 'mastodon', 'features', 'emoji', 'emoji_map.json'))).keys.freeze
  LIMIT = 20

  def validate(reaction)
    return if reaction.name.blank?

    reaction.errors.add(:name, I18n.t('reactions.errors.unrecognized_emoji')) if reaction.custom_emoji_id.blank? && !unicode_emoji?(reaction.name)

  end

  private

  def unicode_emoji?(name)
    SUPPORTED_EMOJIS.include?(name)
  end
end
