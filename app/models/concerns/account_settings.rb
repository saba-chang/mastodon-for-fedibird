# frozen_string_literal: true

module AccountSettings
  extend ActiveSupport::Concern

  def noindex?
    local? ? user&.noindex? : settings['noindex']
  end

  def hide_network?
    local? ? user&.hide_network? : settings['hide_network']
  end

  def hide_statuses_count?
    local? ? user&.hide_statuses_count? : settings['hide_statuses_count']
  end

  def hide_following_count?
    local? ? user&.hide_following_count? : settings['hide_following_count']
  end

  def hide_followers_count?
    local? ? user&.hide_followers_count? : settings['hide_followers_count']
  end

end
