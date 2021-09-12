# frozen_string_literal: true

class PublishEmojiReactionWorker
  include Sidekiq::Worker
  include Redisable
  include RoutingHelper

  def perform(status_id, name)
    status  = Status.find(status_id)
    payload = status.grouped_emoji_reactions.find { |emoji_reaction| emoji_reaction['name'] == name }
    payload ||= { name: name, count: 0, account_ids: [] }

    payload['status_id'] = status_id.to_s

    json = Oj.dump(event: :'emoji_reaction', payload: payload)

    FeedManager.instance.with_active_accounts do |account|
      redis.publish("timeline:#{account.id}", json) if redis.exists?("subscribed:timeline:#{account.id}")
    end
  rescue ActiveRecord::RecordNotFound
    true
  end
end
