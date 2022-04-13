# frozen_string_literal: true

class ActivityPub::EmojiSerializer < ActivityPub::Serializer
  include RoutingHelper

  context_extensions :emoji

  attributes :id, :type, :name, :updated

  has_one :icon

  class RemoteImageSerializer < ActivityPub::ImageSerializer
    def url
      object.instance.image_remote_url
    end
  end
  
  def self.serializer_for(model, options)
    case model.class.name
    when 'Paperclip::Attachment'
      if model.instance.local?
        ActivityPub::ImageSerializer
      else
        RemoteImageSerializer
      end
    end
  end
  
  def id
    ActivityPub::TagManager.instance.uri_for(object)
  end

  def type
    'Emoji'
  end

  def icon
    object.image
  end

  def updated
    object.updated_at.iso8601
  end

  def name
    ":#{object.shortcode}:"
  end
end
