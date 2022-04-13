# frozen_string_literal: true

class EmojiReactionsController < ApplicationController
  before_action :set_emoji_reaction
  before_action :set_cache_headers

  def show
    respond_to do |format|
      format.json do
        expires_in 3.minutes, public: true
        render_with_cache json: @emoji_reaction, content_type: 'application/activity+json', serializer: ActivityPub::EmojiReactionSerializer, adapter: ActivityPub::Adapter
      end
    end
  end

  private

  def set_emoji_reaction
    @emoji_reaction = EmojiReaction.local.find(params[:id])
  end
end
