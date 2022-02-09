# frozen_string_literal: true

module AccountSettings
  extend ActiveSupport::Concern

  included do
    after_initialize :setting_initialize
  end

  def cat?
    true & settings['is_cat']
  end

  alias cat cat?

  def cat=(val)
    settings['is_cat'] = true & ActiveModel::Type::Boolean.new.cast(val)
  end

  def cat_ears_color
    settings['cat_ears_color']
  end

  def birthday
    settings['birthday']
  end

  def birthday=(val)
    settings['birthday'] = ActiveRecord::Type::Date.new.cast(val)
  end

  def location
    settings['location']
  end

  def location=(val)
    settings['location'] = val
  end

  def noindex?
    true & (local? ? user&.noindex? : settings['noindex'])
  end

  def hide_network?
    true & (local? ? user&.hide_network? : settings['hide_network'])
  end

  def hide_statuses_count?
    true & (local? ? user&.hide_statuses_count? : settings['hide_statuses_count'])
  end

  def hide_following_count?
    true & (local? ? user&.hide_following_count? : settings['hide_following_count'])
  end

  def hide_followers_count?
    true & (local? ? user&.hide_followers_count? : settings['hide_followers_count'])
  end

  def other_settings
    local? && user ? settings.merge(
      {
        'noindex'              => user.setting_noindex,
        'hide_network'         => user.setting_hide_network,
        'hide_statuses_count'  => user.setting_hide_statuses_count,
        'hide_following_count' => user.setting_hide_following_count,
        'hide_followers_count' => user.setting_hide_followers_count,
        'enable_reaction'      => user.setting_enable_reaction,
      }
    ) : settings
  end

  # Called by blurhash_transcoder
  def blurhash=(val)
    settings['cat_ears_color'] = "##{Blurhash::Base83::decode83(val.slice(2,4)).to_s(16).rjust(6, '0')}"
  end

  private

  def setting_initialize
    self[:settings] = {} if has_attribute?(:settings) && self[:settings] === "{}"
  end
end
