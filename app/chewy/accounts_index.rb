# frozen_string_literal: true

class AccountsIndex < Chewy::Index
  settings index: { refresh_interval: '5m' }, analysis: {
    filter: {
      english_stop: {
        type: 'stop',
        stopwords: '_english_',
      },
      english_stemmer: {
        type: 'stemmer',
        language: 'english',
      },
      english_possessive_stemmer: {
        type: 'stemmer',
        language: 'possessive_english',
      },
    },

    char_filter: {
      tsconvert: {
        type: 'stconvert',
        keep_both: false,
        delimiter: '#',
        convert_type: 't2s',
      },
    },

    tokenizer: {
      edge_ngram: {
        type: 'edge_ngram',
        min_gram: 1,
        max_gram: 15,
      },

      kuromoji_user_dict: {
        type: 'kuromoji_tokenizer',
        user_dictionary: 'userdic.txt',
      },

      nori_user_dict: {
        type: 'nori_tokenizer',
        decompound_mode: 'mixed',
      },
    },

    analyzer: {
      title: {
        tokenizer: 'whitespace',
        filter: %w(lowercase asciifolding cjk_width),
      },

      ja_title: {
        type: 'custom',
        char_filter: %w(
          icu_normalizer
          kuromoji_iteration_mark
        ),
        tokenizer: 'kuromoji_user_dict',
        filter: %w(lowercase asciifolding cjk_width),
      },

      ko_title: {
        tokenizer: 'nori_user_dict',
        filter: %w(lowercase asciifolding cjk_width),
      },

      zh_title: {
        tokenizer: 'ik_max_word',
        filter: %w(lowercase asciifolding cjk_width),
      },

      content: {
        tokenizer: 'uax_url_email',
        filter: %w(
          english_possessive_stemmer
          lowercase
          asciifolding
          cjk_width
          english_stop
          english_stemmer
        ),
      },

      ja_content: {
        type: 'custom',
        char_filter: %w(
          icu_normalizer
          kuromoji_iteration_mark
        ),
        tokenizer: 'kuromoji_user_dict',
        filter: %w(
          kuromoji_baseform
          kuromoji_part_of_speech
          ja_stop
          kuromoji_stemmer
          kuromoji_number
          cjk_width
          lowercase
        ),
      },

      ko_content: {
        tokenizer: 'nori_user_dict',
        filter: %w(
          english_possessive_stemmer
          lowercase
          asciifolding
          cjk_width
          english_stop
          english_stemmer
        ),
      },

      zh_content: {
        tokenizer: 'ik_max_word',
        filter: %w(
          english_possessive_stemmer
          lowercase
          asciifolding
          cjk_width
          english_stop
          english_stemmer
        ),
        char_filter: %w(tsconvert),
      },

      edge_ngram: {
        tokenizer: 'edge_ngram',
        filter: %w(lowercase asciifolding cjk_width),
      },
    },
  }

  index_scope ::Account.searchable.includes(:account_stat), delete_if: ->(account) { account.destroyed? || !account.searchable? }

  root date_detection: false do
    field :id, type: 'long'

    field :display_name, type: 'text', analyzer: 'title' do
      field :edge_ngram, type: 'text', analyzer: 'edge_ngram', search_analyzer: 'title'
      field :ja_stemmed, type: 'text', analyzer: 'ja_title', search_analyzer: 'title'
      field :ko_stemmed, type: 'text', analyzer: 'ko_title', search_analyzer: 'title'
      field :zh_stemmed, type: 'text', analyzer: 'zh_title', search_analyzer: 'title'
    end

    field :acct, type: 'text', analyzer: 'title', value: ->(account) { [account.username, account.domain].compact.join('@') } do
      field :edge_ngram, type: 'text', analyzer: 'edge_ngram', search_analyzer: 'title'
    end

    field :actor_type, type: 'keyword', normalizer: 'keyword'

    field :text, type: 'text', value: ->(account) { account.index_text } do
      field :en_stemmed, type: 'text', analyzer: 'content'
      field :ja_stemmed, type: 'text', analyzer: 'ja_content'
      field :ko_stemmed, type: 'text', analyzer: 'ko_content'
      field :zh_stemmed, type: 'text', analyzer: 'zh_content'
    end

    field :discoverable, type: 'boolean'

    field :following_count, type: 'long', value: ->(account) { account.following.local.count }
    field :followers_count, type: 'long', value: ->(account) { account.followers.local.count }
    field :subscribing_count, type: 'long', value: ->(account) { account.subscribing.local.count }
    field :last_status_at, type: 'date', value: ->(account) { account.last_status_at || account.created_at }
  end
end
