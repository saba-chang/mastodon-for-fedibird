# frozen_string_literal: true

class StatusesIndex < Chewy::Index
  settings index: {
    refresh_interval: '15m',
    number_of_shards: 1,
    number_of_replicas: 0,
  },
  analysis: {
    tokenizer: {
      sudachi_tokenizer: {
        type: 'sudachi_tokenizer',
        discard_punctuation: true,
        resources_path: '/etc/elasticsearch/sudachi',
        settings_path: '/etc/elasticsearch/sudachi/sudachi.json',
      },
    },
    analyzer: {
      content: {
        filter: %w(
          lowercase
          cjk_width
          sudachi_part_of_speech
          sudachi_ja_stop
          sudachi_baseform
          search
        ),
        tokenizer: 'sudachi_tokenizer',
        type: 'custom',
      },
    },
    filter: {
      search: {
        type: 'sudachi_split',
        mode: 'search',
      },
    },
  }

  index_scope ::Status.unscoped.kept.without_reblogs.includes(:media_attachments, :preloadable_poll)

  crutch :mentions do |collection|
    data = ::Mention.where(status_id: collection.map(&:id)).where(account: Account.local, silent: false).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :favourites do |collection|
    data = ::Favourite.where(status_id: collection.map(&:id)).where(account: Account.local).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :reblogs do |collection|
    data = ::Status.where(reblog_of_id: collection.map(&:id)).where(account: Account.local).pluck(:reblog_of_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :bookmarks do |collection|
    data = ::Bookmark.where(status_id: collection.map(&:id)).where(account: Account.local).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :emoji_reactions do |collection|
    data = ::EmojiReaction.where(status_id: collection.map(&:id)).where(account: Account.local).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :status_references do |collection|
    data = ::StatusReference.joins(:status).where(target_status_id: collection.map(&:id)).where(status: { account: Account.local }).pluck(:target_status_id, :'status.account_id')
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  root date_detection: false do
    field :id, type: 'long'
    field :account_id, type: 'long'

    field :text, type: 'text', value: ->(status) { status.index_text } do
      field :stemmed, type: 'text', analyzer: 'content'
    end

    field :searchable_by, type: 'long', value: ->(status, crutches) { status.searchable_by(crutches) }
    field :searchability, type: 'keyword', value: ->(status) { status.compute_searchability }
  end
end
