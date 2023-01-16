# frozen_string_literal: true

class UserSettingsDecorator
  attr_reader :user, :settings

  def initialize(user)
    @user = user
  end

  def update(settings)
    @settings = settings
    process_update
    profile_change?
  end

  private

  PROFILE_KEYS = %w(
    setting_noindex
    setting_hide_network
    setting_hide_statuses_count
    setting_hide_following_count
    setting_hide_followers_count
    setting_enable_reaction
  ).freeze

  def profile_change?
    settings.keys.intersection(PROFILE_KEYS).any?
  end

  def process_update
    user.settings['notification_emails']               = merged_notification_emails if change?('notification_emails')
    user.settings['interactions']                      = merged_interactions if change?('interactions')
    user.settings['default_privacy']                   = default_privacy_preference if change?('setting_default_privacy')
    user.settings['default_sensitive']                 = default_sensitive_preference if change?('setting_default_sensitive')
    user.settings['default_language']                  = default_language_preference if change?('setting_default_language')
    user.settings['unfollow_modal']                    = unfollow_modal_preference if change?('setting_unfollow_modal')
    user.settings['unsubscribe_modal']                 = unsubscribe_modal_preference if change?('setting_unsubscribe_modal')
    user.settings['boost_modal']                       = boost_modal_preference if change?('setting_boost_modal')
    user.settings['delete_modal']                      = delete_modal_preference if change?('setting_delete_modal')
    user.settings['post_reference_modal']              = post_reference_modal_preference if change?('setting_post_reference_modal')
    user.settings['add_reference_modal']               = add_reference_modal_preference if change?('setting_add_reference_modal')
    user.settings['unselect_reference_modal']          = unselect_reference_modal_preference if change?('setting_unselect_reference_modal')
    user.settings['auto_play_gif']                     = auto_play_gif_preference if change?('setting_auto_play_gif')
    user.settings['display_media']                     = display_media_preference if change?('setting_display_media')
    user.settings['expand_spoilers']                   = expand_spoilers_preference if change?('setting_expand_spoilers')
    user.settings['reduce_motion']                     = reduce_motion_preference if change?('setting_reduce_motion')
    user.settings['disable_swiping']                   = disable_swiping_preference if change?('setting_disable_swiping')
    user.settings['system_font_ui']                    = system_font_ui_preference if change?('setting_system_font_ui')
    user.settings['noindex']                           = noindex_preference if change?('setting_noindex')
    user.settings['theme']                             = theme_preference if change?('setting_theme')
    user.settings['hide_network']                      = hide_network_preference if change?('setting_hide_network')
    user.settings['aggregate_reblogs']                 = aggregate_reblogs_preference if change?('setting_aggregate_reblogs')
    user.settings['show_application']                  = show_application_preference if change?('setting_show_application')
    user.settings['advanced_layout']                   = advanced_layout_preference if change?('setting_advanced_layout')
    user.settings['use_blurhash']                      = use_blurhash_preference if change?('setting_use_blurhash')
    user.settings['use_pending_items']                 = use_pending_items_preference if change?('setting_use_pending_items')
    user.settings['trends']                            = trends_preference if change?('setting_trends')
    user.settings['crop_images']                       = crop_images_preference if change?('setting_crop_images')
    user.settings['confirm_domain_block']              = confirm_domain_block_preference if change?('setting_confirm_domain_block')
    user.settings['show_follow_button_on_timeline']    = show_follow_button_on_timeline_preference if change?('setting_show_follow_button_on_timeline')
    user.settings['show_subscribe_button_on_timeline'] = show_subscribe_button_on_timeline_preference if change?('setting_show_subscribe_button_on_timeline')
    user.settings['show_followed_by']                  = show_followed_by_preference if change?('setting_show_followed_by')
    user.settings['follow_button_to_list_adder']       = follow_button_to_list_adder_preference if change?('setting_follow_button_to_list_adder')
    user.settings['show_navigation_panel']             = show_navigation_panel_preference if change?('setting_show_navigation_panel')
    user.settings['show_quote_button']                 = show_quote_button_preference if change?('setting_show_quote_button')
    user.settings['show_bookmark_button']              = show_bookmark_button_preference if change?('setting_show_bookmark_button')
    user.settings['show_target']                       = show_target_preference if change?('setting_show_target')
    user.settings['place_tab_bar_at_bottom']           = place_tab_bar_at_bottom_preference if change?('setting_place_tab_bar_at_bottom')
    user.settings['show_tab_bar_label']                = show_tab_bar_label_preference if change?('setting_show_tab_bar_label')
    user.settings['enable_limited_timeline']           = enable_limited_timeline_preference if change?('setting_enable_limited_timeline')
    user.settings['enable_reaction']                   = enable_reaction_preference if change?('setting_enable_reaction')
    user.settings['compact_reaction']                  = compact_reaction_preference if change?('setting_compact_reaction')
    user.settings['show_reply_tree_button']            = show_reply_tree_button_preference if change?('setting_show_reply_tree_button')
    user.settings['hide_statuses_count']               = hide_statuses_count_preference if change?('setting_hide_statuses_count')
    user.settings['hide_following_count']              = hide_following_count_preference if change?('setting_hide_following_count')
    user.settings['hide_followers_count']              = hide_followers_count_preference if change?('setting_hide_followers_count')
    user.settings['disable_joke_appearance']           = disable_joke_appearance_preference if change?('setting_disable_joke_appearance')
    user.settings['new_features_policy']               = new_features_policy if change?('setting_new_features_policy')
    user.settings['theme_instance_ticker']             = theme_instance_ticker if change?('setting_theme_instance_ticker')
    user.settings['theme_public']                      = theme_public if change?('setting_theme_public')
    user.settings['enable_status_reference']           = enable_status_reference_preference if change?('setting_enable_status_reference')
    user.settings['match_visibility_of_references']    = match_visibility_of_references_preference if change?('setting_match_visibility_of_references')
    user.settings['hexagon_avatar']                    = hexagon_avatar_preference if change?('setting_hexagon_avatar')
    user.settings['enable_empty_column']               = enable_empty_column_preference if change?('setting_enable_empty_column')
    user.settings['content_font_size']                 = content_font_size_preference if change?('setting_content_font_size')
    user.settings['info_font_size']                    = info_font_size_preference if change?('setting_info_font_size')
    user.settings['content_emoji_reaction_size']       = content_emoji_reaction_size_preference if change?('setting_content_emoji_reaction_size')
    user.settings['hide_bot_on_public_timeline']       = hide_bot_on_public_timeline_preference if change?('setting_hide_bot_on_public_timeline')
    user.settings['confirm_follow_from_bot']           = confirm_follow_from_bot_preference if change?('setting_confirm_follow_from_bot')
    user.settings['default_search_searchability']      = default_search_searchability_preference if change?('setting_default_search_searchability')
    user.settings['show_reload_button']                = show_reload_button_preference if change?('setting_show_reload_button')
    user.settings['default_column_width']              = default_column_width_preference if change?('setting_default_column_width')
  end

  def merged_notification_emails
    user.settings['notification_emails'].merge coerced_settings('notification_emails').to_h
  end

  def merged_interactions
    user.settings['interactions'].merge coerced_settings('interactions').to_h
  end

  def default_privacy_preference
    settings['setting_default_privacy']
  end

  def default_sensitive_preference
    boolean_cast_setting 'setting_default_sensitive'
  end

  def unfollow_modal_preference
    boolean_cast_setting 'setting_unfollow_modal'
  end

  def unsubscribe_modal_preference
    boolean_cast_setting 'setting_unsubscribe_modal'
  end

  def boost_modal_preference
    boolean_cast_setting 'setting_boost_modal'
  end

  def delete_modal_preference
    boolean_cast_setting 'setting_delete_modal'
  end

  def post_reference_modal_preference
    boolean_cast_setting 'setting_post_reference_modal'
  end

  def add_reference_modal_preference
    boolean_cast_setting 'setting_add_reference_modal'
  end

  def unselect_reference_modal_preference
    boolean_cast_setting 'setting_unselect_reference_modal'
  end

  def system_font_ui_preference
    boolean_cast_setting 'setting_system_font_ui'
  end

  def auto_play_gif_preference
    boolean_cast_setting 'setting_auto_play_gif'
  end

  def display_media_preference
    settings['setting_display_media']
  end

  def expand_spoilers_preference
    boolean_cast_setting 'setting_expand_spoilers'
  end

  def reduce_motion_preference
    boolean_cast_setting 'setting_reduce_motion'
  end

  def disable_swiping_preference
    boolean_cast_setting 'setting_disable_swiping'
  end

  def noindex_preference
    boolean_cast_setting 'setting_noindex'
  end

  def hide_network_preference
    boolean_cast_setting 'setting_hide_network'
  end

  def show_application_preference
    boolean_cast_setting 'setting_show_application'
  end

  def theme_preference
    settings['setting_theme']
  end

  def default_language_preference
    settings['setting_default_language']
  end

  def aggregate_reblogs_preference
    boolean_cast_setting 'setting_aggregate_reblogs'
  end

  def advanced_layout_preference
    boolean_cast_setting 'setting_advanced_layout'
  end

  def use_blurhash_preference
    boolean_cast_setting 'setting_use_blurhash'
  end

  def use_pending_items_preference
    boolean_cast_setting 'setting_use_pending_items'
  end

  def trends_preference
    boolean_cast_setting 'setting_trends'
  end

  def crop_images_preference
    boolean_cast_setting 'setting_crop_images'
  end

  def confirm_domain_block_preference
    boolean_cast_setting 'setting_confirm_domain_block'
  end

  def show_follow_button_on_timeline_preference
    boolean_cast_setting 'setting_show_follow_button_on_timeline'
  end

  def show_subscribe_button_on_timeline_preference
    boolean_cast_setting 'setting_show_subscribe_button_on_timeline'
  end

  def show_followed_by_preference
    boolean_cast_setting 'setting_show_followed_by'
  end

  def follow_button_to_list_adder_preference
    boolean_cast_setting 'setting_follow_button_to_list_adder'
  end

  def show_navigation_panel_preference
    boolean_cast_setting 'setting_show_navigation_panel'
  end

  def show_quote_button_preference
    boolean_cast_setting 'setting_show_quote_button'
  end

  def show_bookmark_button_preference
    boolean_cast_setting 'setting_show_bookmark_button'
  end

  def show_target_preference
    boolean_cast_setting 'setting_show_target'
  end

  def place_tab_bar_at_bottom_preference
    boolean_cast_setting 'setting_place_tab_bar_at_bottom'
  end

  def show_tab_bar_label_preference
    boolean_cast_setting 'setting_show_tab_bar_label'
  end

  def enable_limited_timeline_preference
    boolean_cast_setting 'setting_enable_limited_timeline'
  end

  def enable_reaction_preference
    boolean_cast_setting 'setting_enable_reaction'
  end

  def compact_reaction_preference
    boolean_cast_setting 'setting_compact_reaction'
  end

  def show_reply_tree_button_preference
    boolean_cast_setting 'setting_show_reply_tree_button'
  end

  def hide_statuses_count_preference
    boolean_cast_setting 'setting_hide_statuses_count'
  end

  def hide_following_count_preference
    boolean_cast_setting 'setting_hide_following_count'
  end

  def hide_followers_count_preference
    boolean_cast_setting 'setting_hide_followers_count'
  end

  def disable_joke_appearance_preference
    boolean_cast_setting 'setting_disable_joke_appearance'
  end

  def new_features_policy
    settings['setting_new_features_policy']
  end

  def theme_instance_ticker
    settings['setting_theme_instance_ticker']
  end

  def theme_public
    boolean_cast_setting 'setting_theme_public'
  end

  def hexagon_avatar_preference
    boolean_cast_setting 'setting_hexagon_avatar'
  end

  def enable_status_reference_preference
    boolean_cast_setting 'setting_enable_status_reference'
  end

  def match_visibility_of_references_preference
    boolean_cast_setting 'setting_match_visibility_of_references'
  end

  def enable_empty_column_preference
    boolean_cast_setting 'setting_enable_empty_column'
  end

  def content_font_size_preference
    settings['setting_content_font_size']
  end

  def info_font_size_preference
    settings['setting_info_font_size']
  end

  def content_emoji_reaction_size_preference
    settings['setting_content_emoji_reaction_size']
  end

  def hide_bot_on_public_timeline_preference
    boolean_cast_setting 'setting_hide_bot_on_public_timeline'
  end

  def confirm_follow_from_bot_preference
    boolean_cast_setting 'setting_confirm_follow_from_bot'
  end

  def default_search_searchability_preference
    settings['setting_default_search_searchability']
  end

  def show_reload_button_preference
    boolean_cast_setting 'setting_show_reload_button'
  end

  def default_column_width_preference
    settings['setting_default_column_width']
  end

  def boolean_cast_setting(key)
    ActiveModel::Type::Boolean.new.cast(settings[key])
  end

  def coerced_settings(key)
    coerce_values settings.fetch(key, {})
  end

  def coerce_values(params_hash)
    params_hash.transform_values { |x| ActiveModel::Type::Boolean.new.cast(x) }
  end

  def change?(key)
    !settings[key].nil?
  end
end
