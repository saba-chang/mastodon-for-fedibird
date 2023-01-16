# frozen_string_literal: true
# == Schema Information
#
# Table name: statuses
#
#  id                     :bigint(8)        not null, primary key
#  uri                    :string
#  text                   :text             default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  in_reply_to_id         :bigint(8)
#  reblog_of_id           :bigint(8)
#  url                    :string
#  sensitive              :boolean          default(FALSE), not null
#  visibility             :integer          default("public"), not null
#  spoiler_text           :text             default(""), not null
#  reply                  :boolean          default(FALSE), not null
#  language               :string
#  conversation_id        :bigint(8)
#  local                  :boolean
#  account_id             :bigint(8)        not null
#  application_id         :bigint(8)
#  in_reply_to_account_id :bigint(8)
#  poll_id                :bigint(8)
#  deleted_at             :datetime
#  quote_id               :bigint(8)
#  expired_at             :datetime
#  searchability          :integer
#

class Status < ApplicationRecord
  before_destroy :unlink_from_conversations

  include Discard::Model
  include Paginable
  include Cacheable
  include StatusThreadingConcern
  include RateLimitable
  include Redisable

  rate_limit by: :account, family: :statuses

  self.discard_column = :deleted_at

  # If `override_timestamps` is set at creation time, Snowflake ID creation
  # will be based on current time instead of `created_at`
  attr_accessor :override_timestamps, :circle, :expires_at, :expires_action

  update_index('statuses', :proper)

  enum visibility: [:public, :unlisted, :private, :direct, :limited, :mutual], _suffix: :visibility
  enum searchability: [:public, :unlisted, :private, :direct, :limited, :mutual], _suffix: :searchability

  belongs_to :application, class_name: 'Doorkeeper::Application', optional: true

  belongs_to :account, inverse_of: :statuses
  belongs_to :in_reply_to_account, foreign_key: 'in_reply_to_account_id', class_name: 'Account', optional: true
  belongs_to :conversation, optional: true, inverse_of: :statuses
  belongs_to :preloadable_poll, class_name: 'Poll', foreign_key: 'poll_id', optional: true

  has_one :owned_conversation, class_name: 'Conversation', foreign_key: 'parent_status_id', inverse_of: :parent_status

  belongs_to :thread, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :replies, optional: true
  belongs_to :reblog, foreign_key: 'reblog_of_id', class_name: 'Status', inverse_of: :reblogs, optional: true
  belongs_to :quote, foreign_key: 'quote_id', class_name: 'Status', inverse_of: :quoted, optional: true

  has_many :favourites, inverse_of: :status, dependent: :destroy
  has_many :bookmarks, inverse_of: :status, dependent: :destroy
  has_many :emoji_reactions, inverse_of: :status, dependent: :destroy
  has_many :reblogs, foreign_key: 'reblog_of_id', class_name: 'Status', inverse_of: :reblog, dependent: :destroy
  has_many :replies, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :thread
  has_many :mentions, dependent: :destroy, inverse_of: :status
  has_many :active_mentions, -> { active }, class_name: 'Mention', inverse_of: :status
  has_many :media_attachments, dependent: :nullify
  has_many :quoted, foreign_key: 'quote_id', class_name: 'Status', inverse_of: :quote, dependent: :nullify
  has_many :capability_tokens, class_name: 'StatusCapabilityToken', inverse_of: :status, dependent: :destroy

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :preview_cards

  has_many :reference_relationships, class_name: 'StatusReference', foreign_key: :status_id, dependent: :destroy
  has_many :references, through: :reference_relationships, source: :target_status
  has_many :referred_by_relationships, class_name: 'StatusReference', foreign_key: :target_status_id, dependent: :destroy
  has_many :referred_by, through: :referred_by_relationships, source: :status

  has_one :notification, as: :activity, dependent: :destroy
  has_one :status_stat, inverse_of: :status
  has_one :poll, inverse_of: :status, dependent: :destroy
  has_one :status_expire, inverse_of: :status

  validates :uri, uniqueness: true, presence: true, unless: :local?
  validates :text, presence: true, unless: -> { with_media? || reblog? }
  validates_with StatusLengthValidator
  validates_with DisallowedHashtagsValidator
  validates :reblog, uniqueness: { scope: :account }, if: :reblog?
  validates :visibility, exclusion: { in: %w(direct) }, if: :reblog?
  validates :quote_visibility, inclusion: { in: %w(public unlisted) }, if: :quote?
  validates_with ExpiresValidator, on: :create, if: :local?

  accepts_nested_attributes_for :poll

  default_scope { recent.kept.not_expired }

  scope :recent, -> { reorder(id: :desc) }
  scope :remote, -> { where(local: false).where.not(uri: nil) }
  scope :local,  -> { where(local: true).or(where(uri: nil)) }

  scope :not_expired, -> { where(expired_at: nil) }
  scope :include_expired, -> { unscoped.recent.kept }
  scope :with_accounts, ->(ids) { where(id: ids).includes(:account) }
  scope :without_replies, -> { where('statuses.reply = FALSE OR statuses.in_reply_to_account_id = statuses.account_id') }
  scope :without_reblogs, -> { where('statuses.reblog_of_id IS NULL') }
  scope :with_public_visibility, -> { where(visibility: :public) }
  scope :tagged_with, ->(tag_ids) { joins(:statuses_tags).where(statuses_tags: { tag_id: tag_ids }) }
  scope :in_chosen_languages, ->(account) { where(language: nil).or where(language: account.chosen_languages) }
  scope :mentioned_with, ->(account) { joins(:mentions).where(mentions: { account_id: account }) }
  scope :excluding_silenced_accounts, -> { left_outer_joins(:account).where(accounts: { silenced_at: nil }) }
  scope :including_silenced_accounts, -> { left_outer_joins(:account).where.not(accounts: { silenced_at: nil }) }
  scope :not_excluded_by_account, ->(account) { where.not(account_id: account.excluded_from_timeline_account_ids) }
  scope :not_domain_blocked_by_account, ->(account) { account.excluded_from_timeline_domains.blank? ? left_outer_joins(:account) : left_outer_joins(:account).where('accounts.domain IS NULL OR accounts.domain NOT IN (?)', account.excluded_from_timeline_domains) }
  scope :tagged_with_all, ->(tag_ids) {
    Array(tag_ids).reduce(self) do |result, id|
      result.joins("INNER JOIN statuses_tags t#{id} ON t#{id}.status_id = statuses.id AND t#{id}.tag_id = #{id}")
    end
  }
  scope :tagged_with_none, ->(tag_ids) {
    Array(tag_ids).reduce(self) do |result, id|
      result.joins("LEFT OUTER JOIN statuses_tags t#{id} ON t#{id}.status_id = statuses.id AND t#{id}.tag_id = #{id}")
            .where("t#{id}.tag_id IS NULL")
    end
  }
  scope :unset_searchability, -> { where(searchability: nil, reblog_of_id: nil) }

  cache_associated :application,
                   :media_attachments,
                   :conversation,
                   :status_stat,
                   :status_expire,
                   :tags,
                   :preview_cards,
                   :preloadable_poll,
                   references: { account: :account_stat },
                   account: [:account_stat, :user],
                   active_mentions: { account: :account_stat },
                   reblog: [
                     :application,
                     :tags,
                     :preview_cards,
                     :media_attachments,
                     :conversation,
                     :status_stat,
                     :status_expire,
                     :preloadable_poll,
                     references: { account: :account_stat },
                     account: [:account_stat, :user],
                     active_mentions: { account: :account_stat },
                   ],
                   thread: { account: :account_stat }

  delegate :domain, to: :account, prefix: true

  REAL_TIME_WINDOW = 6.hours

  def searchable_by(preloaded = nil)
    ids = []

    ids << account_id if local?

    if preloaded.nil?
      ids += mentions.where(account: Account.local, silent: false).pluck(:account_id)
      ids += favourites.where(account: Account.local).pluck(:account_id)
      ids += reblogs.where(account: Account.local).pluck(:account_id)
      ids += bookmarks.where(account: Account.local).pluck(:account_id)
      ids += emoji_reactions.where(account: Account.local).pluck(:account_id)
      ids += referred_by_statuses.where(account: Account.local).pluck(:account_id)
    else
      ids += preloaded.mentions[id] || []
      ids += preloaded.favourites[id] || []
      ids += preloaded.reblogs[id] || []
      ids += preloaded.bookmarks[id] || []
      ids += preloaded.emoji_reactions[id] || []
      ids += preloaded.status_references[id] || []
    end

    ids.uniq
  end

  def compute_searchability
    searchability || Status.searchabilities.invert.fetch([Account.searchabilities[account.searchability], Status.visibilities[visibility] || 0].max, nil) || 'direct'
  end

  def reply?
    !in_reply_to_id.nil? || attributes['reply']
  end

  def local?
    attributes['local'] || uri.nil?
  end

  def in_reply_to_local_account?
    reply? && thread&.account&.local?
  end

  def reblog?
    !reblog_of_id.nil?
  end

  def quote?
    !quote_id.nil? && quote
  end

  def emoji_reaction?
    status_stat&.emoji_reactions_cache.present?
  end

  def quote_visibility
    quote&.visibility
  end

  def mentioning?(source_account_id)
    source_account_id = source_account_id.id if source_account_id.is_a?(Account)

    mentions.where(account_id: source_account_id).exists?
  end

  def within_realtime_window?
    created_at >= REAL_TIME_WINDOW.ago
  end

  def verb
    if destroyed?
      :delete
    else
      reblog? ? :share : :post
    end
  end

  def object_type
    reply? ? :comment : :note
  end

  def proper
    reblog? ? Status.include_expired.with_discarded.find(reblog_of_id) : self
  end

  def content
    proper.text
  end

  def target
    reblog
  end

  def preview_card
    preview_cards.first
  end

  def hidden?
    !distributable?
  end

  def distributable?
    public_visibility? || unlisted_visibility?
  end

  def public_safety?
    distributable? && (!with_media? || non_sensitive_with_media?) && !account.silenced? && !account.suspended?
  end

  def sign?
    distributable? || limited_visibility?
  end

  def with_media?
    media_attachments.any?
  end

  def expired?
    !expired_at.nil?
  end

  def expires?
    status_expire.present?
  end

  def expiry
    expires? && status_expire&.expires_mark? && status_expire&.expires_at || expired_at
  end

  def non_sensitive_with_media?
    !sensitive? && with_media?
  end

  def reported?
    @reported ||= Report.where(target_account: account).unresolved.where('? = ANY(status_ids)', id).exists?
  end

  def emojis
    return @emojis if defined?(@emojis)

    fields  = [spoiler_text, text]
    fields += preloadable_poll.options unless preloadable_poll.nil?

    @emojis = CustomEmoji.from_text(fields.join(' '), account.domain) + (quote? ? CustomEmoji.from_text([quote.spoiler_text, quote.text].join(' '), quote.account.domain) : [])
  end

  def index_text
    @index_text ||= [spoiler_text, Formatter.instance.plaintext(self)].concat(media_attachments.map(&:description)).concat(preloadable_poll ? preloadable_poll.options : []).concat(quote? ? ["QT: [#{quote.url || ActivityPub::TagManager.instance.url_for(quote)}]"] : []).filter(&:present?).join("\n\n")
  end

  def replies_count
    status_stat&.replies_count || 0
  end

  def reblogs_count
    status_stat&.reblogs_count || 0
  end

  def favourites_count
    status_stat&.favourites_count || 0
  end

  def emoji_reactions_count
    status_stat&.emoji_reactions_count || 0
  end

  def status_references_count
    status_stat&.status_references_count || 0
  end

  def status_referred_by_count
    status_stat&.status_referred_by_count || 0
  end

  def account_ids(recursive: true)
    ids = (Oj.load(status_stat&.emoji_reactions_cache || '', mode: :strict) || []).flat_map { |emoji_reaction| emoji_reaction['account_ids'] }
    ids << account_id.to_s

    if recursive
      ids.concat(quote.account_ids(recursive: false)) unless quote.nil?
      ids.concat(reblog.account_ids(recursive: false)) unless reblog.nil?
      ids.concat(reblog.quote.account_ids(recursive: false)) unless reblog&.quote.nil?
    end

    ids.uniq
  end

  def grouped_emoji_reactions(account = nil)
    (Oj.load(status_stat&.emoji_reactions_cache || '', mode: :strict) || []).tap do |emoji_reactions|
      if account.present?
        emoji_reactions.each do |emoji_reaction|
          emoji_reaction['me'] = emoji_reaction['account_ids'].include?(account.id.to_s)
          emoji_reaction['account_ids'] -= account.excluded_from_timeline_account_ids.map(&:to_s)
          emoji_reaction['count'] = emoji_reaction['account_ids'].size
        end
      end
    end
  end

  def generate_grouped_emoji_reactions
    records = emoji_reactions.group(:name).order(Arel.sql('MIN(created_at) ASC')).select('name, min(custom_emoji_id) as custom_emoji_id, count(*) as count, array_agg(account_id::text order by created_at) as account_ids').limit(EmojiReactionValidator::LIMIT)
    Oj.dump(ActiveModelSerializers::SerializableResource.new(records, each_serializer: REST::GroupedEmojiReactionSerializer, scope: nil, scope_name: :current_user))
  end

  def refresh_grouped_emoji_reactions!
    generate_grouped_emoji_reactions.tap do |emoji_reactions_cache|
      update_status_stat!(emoji_reactions_count: emoji_reactions.count, emoji_reactions_cache: emoji_reactions_cache)
    end
  end

  def referred_by_statuses(account)
    statuses          = referred_by.includes(:account).to_a
    account_ids       = statuses.map(&:account_id).uniq
    account_relations = Status.relations_map_for_account(account, account_ids)
    status_relations  = Status.relations_map_for_status(account, statuses)

    statuses.reject! { |status| StatusFilter.new(status, account, account_relations, status_relations).filtered? }
    statuses.sort!.reverse!
  end

  def increment_count!(key)
    update_status_stat!(key => public_send(key) + 1)
  end

  def decrement_count!(key)
    update_status_stat!(key => [public_send(key) - 1, 0].max)
  end

  after_create_commit  :increment_counter_caches
  after_destroy_commit :decrement_counter_caches

  after_create_commit :store_uri, if: :local?
  after_create_commit :update_statistics, if: :local?
  after_create_commit :set_status_expire, if: -> { expires_at.present? }
  after_update :update_status_expire, if: -> { expires_at.present? }

  around_create Mastodon::Snowflake::Callbacks

  before_validation :prepare_contents, on: :create, if: :local?
  before_validation :set_reblog, on: :create
  before_validation :set_visibility, on: :create
  before_validation :set_searchability, on: :create
  before_validation :set_conversation, on: :create
  before_validation :set_local, on: :create

  after_create :set_poll_id
  after_create :set_circle

  class << self
    def selectable_visibilities
      visibilities.keys - %w(direct limited)
    end

    def selectable_searchabilities
      searchabilities.keys - %w(unlisted limited mutual)
    end

    def favourites_map(status_ids, account_id)
      Favourite.select('status_id').where(status_id: status_ids).where(account_id: account_id).each_with_object({}) { |f, h| h[f.status_id] = true }
    end

    def bookmarks_map(status_ids, account_id)
      Bookmark.select('status_id').where(status_id: status_ids).where(account_id: account_id).map { |f| [f.status_id, true] }.to_h
    end

    def emoji_reactions_map(status_ids, account_id)
      EmojiReaction.select('status_id').where(status_id: status_ids).where(account_id: account_id).map { |f| [f.status_id, true] }.to_h
    end

    def reblogs_map(status_ids, account_id)
      unscoped.select('reblog_of_id').where(reblog_of_id: status_ids).where(account_id: account_id).each_with_object({}) { |s, h| h[s.reblog_of_id] = true }
    end

    def mutes_map(conversation_ids, account_id)
      ConversationMute.select('conversation_id').where(conversation_id: conversation_ids).where(account_id: account_id).each_with_object({}) { |m, h| h[m.conversation_id] = true }
    end

    def pins_map(status_ids, account_id)
      StatusPin.select('status_id').where(status_id: status_ids).where(account_id: account_id).each_with_object({}) { |p, h| h[p.status_id] = true }
    end

    def relations_map_for_account(account, account_ids)
      return {} if account.nil?

      presenter = AccountRelationshipsPresenter.new(account_ids, account)
      {
        blocking: presenter.blocking,
        blocked_by: presenter.blocked_by,
        muting: presenter.muting,
        following: presenter.following,
        subscribing: presenter.subscribing,
        domain_blocking_by_domain: presenter.domain_blocking,
      }
    end

    def relations_map_for_status(account, statuses)
      return {} if account.nil?

      presenter = StatusRelationshipsPresenter.new(statuses, account)
      {
        reblogs_map: presenter.reblogs_map,
        favourites_map: presenter.favourites_map,
        bookmarks_map: presenter.bookmarks_map,
        emoji_reactions_map: presenter.emoji_reactions_map,
        mutes_map: presenter.mutes_map,
        pins_map: presenter.pins_map,
      }
    end

    def reload_stale_associations!(cached_items)
      account_ids = []

      cached_items.each do |item|
        account_ids << item.account_id
        account_ids << item.reblog.account_id if item.reblog?
      end

      account_ids.uniq!

      return if account_ids.empty?

      accounts = Account.where(id: account_ids).includes(:account_stat, :user).index_by(&:id)

      cached_items.each do |item|
        item.account = accounts[item.account_id]
        item.reblog.account = accounts[item.reblog.account_id] if item.reblog?
      end
    end

    def permitted_statuses_from_ids(ids, account)
      statuses          = Status.with_accounts(ids).to_a
      account_ids       = statuses.map(&:account_id).uniq
      account_relations = relations_map_for_account(account, account_ids)
      status_relations  = relations_map_for_status(account, statuses)

      statuses.reject! { |status| StatusFilter.new(status, account, account_relations, status_relations).filtered? }
      statuses
    end

    def permitted_for(target_account, account)
      visibility = [:public, :unlisted]

      if account.nil?
        where(visibility: visibility)
      elsif target_account.blocking?(account) || (account.domain.present? && target_account.domain_blocking?(account.domain)) # get rid of blocked peeps
        none
      elsif account.id == target_account.id # author can see own stuff
        all
      else
        # followers can see followers-only stuff, but also things they are mentioned in.
        # non-followers can see everything that isn't private/direct, but can see stuff they are mentioned in.
        visibility.push(:private) if account.following?(target_account)

        scope = left_outer_joins(:reblog)

        scope.where(visibility: visibility)
             .or(scope.where(id: account.mentions.select(:status_id)))
             .merge(scope.where(reblog_of_id: nil).or(scope.where.not(reblogs_statuses: { account_id: account.excluded_from_timeline_account_ids })))
      end
    end

    def from_text(text)
      return [] if text.blank?

      text.scan(FetchLinkCardService::URL_PATTERN).map(&:first).uniq.filter_map do |url|
        status =
          if TagManager.instance.local_url?(url)
            ActivityPub::TagManager.instance.uri_to_resource(url, Status)
          else
            EntityCache.instance.status(url)
          end
        status&.distributable? ? status : nil
      end
    end
  end

  def status_stat
    super || build_status_stat
  end

  private

  def set_status_expire
    create_status_expire(expires_at: expires_at, action: expires_action)
  end

  def update_status_expire
    status_expire&.update(expires_at: expires_at, action: expires_action) || set_status_expire
  end

  def update_status_stat!(attrs)
    return if marked_for_destruction? || destroyed?

    status_stat.update(attrs)
  end

  def store_uri
    update_column(:uri, ActivityPub::TagManager.instance.uri_for(self)) if uri.nil?
  end

  def prepare_contents
    text&.strip!
    spoiler_text&.strip!
  end

  def set_reblog
    self.reblog = reblog.reblog if reblog? && reblog.reblog?
  end

  def set_poll_id
    update_column(:poll_id, poll.id) unless poll.nil?
  end

  def set_visibility
    self.visibility = reblog.visibility if reblog? && visibility.nil?
    self.visibility = (account.locked? ? :private : :public) if visibility.nil?
    self.sensitive  = false if sensitive.nil?
  end

  def set_searchability
    return if searchability.nil?

    self.searchability = [Status.searchabilities[searchability], Status.visibilities[visibility]].max
  end

  def set_conversation
    self.thread = thread.reblog if thread&.reblog?

    self.reply = !(in_reply_to_id.nil? && thread.nil?) unless reply

    if reply? && !thread.nil?
      self.in_reply_to_account_id = carried_over_reply_to_account_id
    end

    if conversation_id.nil?
      if reply? && !thread.nil? && circle.nil?
        self.conversation_id = thread.conversation_id
      else
        build_owned_conversation
      end
    end
  end

  def set_circle
    redis.setex(circle_id_key, 3.days.seconds, circle.id) if circle.present?
  end

  def circle_id_key
    "statuses/#{id}/circle_id"
  end

  def carried_over_reply_to_account_id
    if thread.account_id == account_id && thread.reply?
      thread.in_reply_to_account_id
    else
      thread.account_id
    end
  end

  def set_local
    self.local = account.local?
  end

  def update_statistics
    return unless distributable?

    ActivityTracker.increment('activity:statuses:local')
  end

  def increment_counter_caches
    return if direct_visibility?

    account&.increment_count!(:statuses_count)
    reblog&.increment_count!(:reblogs_count) if reblog?
    thread&.increment_count!(:replies_count) if in_reply_to_id.present? && distributable?
  end

  def decrement_counter_caches
    return if direct_visibility?

    account&.decrement_count!(:statuses_count)
    reblog&.decrement_count!(:reblogs_count) if reblog?
    thread&.decrement_count!(:replies_count) if in_reply_to_id.present? && distributable?
  end

  def unlink_from_conversations
    return unless direct_visibility?

    mentioned_accounts = (association(:mentions).loaded? ? mentions : mentions.includes(:account)).map(&:account)
    inbox_owners       = mentioned_accounts.select(&:local?) + (account.local? ? [account] : [])

    inbox_owners.each do |inbox_owner|
      AccountConversation.remove_status(inbox_owner, self)
    end
  end
end
