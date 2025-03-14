# frozen_string_literal: true

class SearchService < BaseService
  def call(query, account, limit, options = {})
    @query   = query&.strip
    @account = account
    @options = options
    @limit   = limit.to_i
    @offset  = options[:type].blank? ? 0 : options[:offset].to_i
    @resolve = options[:resolve] || false

    default_results.tap do |results|
      next if @query.blank? || @limit.zero?

      if url_query?
        results.merge!(url_resource_results) unless url_resource.nil? || @offset.positive? || (@options[:type].present? && url_resource_symbol != @options[:type].to_sym)
      elsif @query.present?
        results[:accounts] = perform_accounts_search! if account_searchable?
        results[:statuses] = perform_statuses_search! if full_text_searchable?
        results[:hashtags] = perform_hashtags_search! if hashtag_searchable?
      end
    end
  end

  private

  def perform_accounts_search!
    AccountSearchService.new.call(
      @query,
      @account,
      limit: @limit,
      resolve: @resolve,
      offset: @offset
    )
  end

  def perform_statuses_search!
    definition = parsed_query.apply(StatusesIndex.filter(term: { searchable_by: @account.id }))

    if @options[:account_id].present?
      definition = definition.filter(term: { account_id: @options[:account_id] })
    end

    if @options[:min_id].present? || @options[:max_id].present?
      range      = {}
      range[:gt] = @options[:min_id].to_i if @options[:min_id].present?
      range[:lt] = @options[:max_id].to_i if @options[:max_id].present?
      definition = definition.filter(range: { id: range })
    end

    results           = definition.limit(@limit).offset(@offset).objects.compact
    account_ids       = results.map(&:account_id)
    account_relations = relations_map_for_account(@account, account_ids)
    status_relations  = relations_map_for_status(@account, results)

    results.reject { |status| StatusFilter.new(status, @account, account_relations, status_relations).filtered? }
  rescue Faraday::ConnectionFailed, Parslet::ParseFailed
    []
  end

  def perform_hashtags_search!
    TagSearchService.new.call(
      @query,
      limit: @limit,
      offset: @offset,
      exclude_unreviewed: @options[:exclude_unreviewed]
    )
  end

  def default_results
    { accounts: [], hashtags: [], statuses: [] }
  end

  def url_query?
    @resolve && /\Ahttps?:\/\//.match?(@query)
  end

  def url_resource_results
    { url_resource_symbol => [url_resource] }
  end

  def url_resource
    @_url_resource ||= ResolveURLService.new.call(@query, on_behalf_of: @account)
  end

  def url_resource_symbol
    url_resource.class.name.downcase.pluralize.to_sym
  end

  def full_text_searchable?
    return false unless Chewy.enabled?

    statuses_search? && !@account.nil? && !((@query.start_with?('#') || @query.include?('@')) && !@query.include?(' '))
  end

  def account_searchable?
    account_search? && !(@query.start_with?('#') || (@query.include?('@') && @query.include?(' ')))
  end

  def hashtag_searchable?
    hashtag_search? && !@query.include?('@')
  end

  def account_search?
    @options[:type].blank? || @options[:type] == 'accounts'
  end

  def hashtag_search?
    @options[:type].blank? || @options[:type] == 'hashtags'
  end

  def statuses_search?
    @options[:type].blank? || @options[:type] == 'statuses'
  end

  def relations_map_for_account(account, account_ids)
    presenter = AccountRelationshipsPresenter.new(account_ids, account)
    {
      blocking: presenter.blocking,
      blocked_by: presenter.blocked_by,
      muting: presenter.muting,
      following: presenter.following,
      domain_blocking: presenter.domain_blocking,
    }
  end

  def relations_map_for_status(account, statuses)
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

  def parsed_query
    SearchQueryTransformer.new.apply(SearchQueryParser.new.parse(@query))
  end
end
