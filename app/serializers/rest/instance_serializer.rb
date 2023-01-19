# frozen_string_literal: true

class REST::InstanceSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :uri, :title, :short_description, :description, :email,
             :version, :urls, :stats, :thumbnail, :max_toot_chars,
             :languages, :registrations, :approval_required, :invites_enabled,
             :configuration,
             :feature_quote, :fedibird_capabilities

  has_one :contact_account, serializer: REST::AccountSerializer

  has_many :rules, serializer: REST::RuleSerializer

  delegate :contact_account, :rules, to: :instance_presenter

  def uri
    Rails.configuration.x.local_domain
  end

  def max_toot_chars
    StatusLengthValidator::MAX_CHARS
  end

  def title
    Setting.site_title
  end

  def short_description
    Setting.site_short_description
  end

  def description
    Setting.site_description
  end

  def email
    Setting.site_contact_email
  end

  def version
    Mastodon::Version.to_s
  end

  def thumbnail
    instance_presenter.thumbnail ? full_asset_url(instance_presenter.thumbnail.file.url) : full_pack_url('media/images/preview.jpg')
  end

  def stats
    {
      user_count: instance_presenter.user_count,
      status_count: instance_presenter.status_count,
      domain_count: instance_presenter.domain_count,
    }
  end

  def urls
    { streaming_api: Rails.configuration.x.streaming_api_base_url }
  end

  def configuration
    {
      accounts: {
        max_favourite_tags: FavouriteTag::LIMIT,
        max_featured_tags: FeaturedTag::LIMIT,
      },

      statuses: {
        max_characters: StatusLengthValidator::MAX_CHARS,
        max_media_attachments: 4,
        characters_reserved_per_url: StatusLengthValidator::URL_PLACEHOLDER_CHARS,
        min_expiration: TimeLimit::VALID_DURATION.min,
        max_expiration: TimeLimit::VALID_DURATION.max,
        supported_expires_actions: StatusExpire::actions.keys,
      },

      media_attachments: {
        supported_mime_types: MediaAttachment::IMAGE_MIME_TYPES + MediaAttachment::VIDEO_MIME_TYPES + MediaAttachment::AUDIO_MIME_TYPES,
        image_size_limit: MediaAttachment::IMAGE_LIMIT,
        image_matrix_limit: Attachmentable::MAX_MATRIX_LIMIT,
        video_size_limit: MediaAttachment::VIDEO_LIMIT,
        video_frame_rate_limit: MediaAttachment::MAX_VIDEO_FRAME_RATE,
        video_matrix_limit: MediaAttachment::MAX_VIDEO_MATRIX_LIMIT,
      },

      polls: {
        max_options: PollValidator::MAX_OPTIONS,
        max_characters_per_option: PollValidator::MAX_OPTION_CHARS,
        min_expiration: PollValidator::MIN_EXPIRATION,
        max_expiration: PollValidator::MAX_EXPIRATION,
      },

      emoji_reactions: {
        max_reactions: EmojiReactionValidator::LIMIT,
      },

      status_references: {
        max_references: StatusReferenceValidator::LIMIT,
      },
    }
  end

  def languages
    [I18n.default_locale]
  end

  def registrations
    Setting.registrations_mode != 'none' && !Rails.configuration.x.single_user_mode
  end

  def approval_required
    Setting.registrations_mode == 'approved'
  end

  def invites_enabled
    Setting.min_invite_role == 'user'
  end

  def feature_quote
    true
  end

  def fedibird_capabilities
    capabilities = [
      :favourite_hashtag,
      :favourite_domain,
      :favourite_list,
      :status_expire,
      :follow_no_delivery,
      :follow_hashtag,
      :subscribe_account,
      :subscribe_domain,
      :subscribe_keyword,
      :timeline_home_visibility,
      :timeline_no_local,
      :timeline_domain,
      :timeline_group,
      :timeline_group_directory,
      :visibility_mutual,
      :visibility_limited,
      :visibility_personal,
      :emoji_reaction,
      :misskey_birthday,
      :misskey_location,
      :status_reference,
      :searchability,
      :status_compact_mode,
      :account_conversations,
    ]

    capabilities << :profile_search unless Chewy.enabled?

    capabilities
  end

  private

  def instance_presenter
    @instance_presenter ||= InstancePresenter.new
  end
end
