# frozen_string_literal: true

class Api::V1::Timelines::PersonalController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:statuses' }, only: [:show]
  before_action :require_user!, only: [:show]
  after_action :insert_pagination_headers, unless: -> { @statuses.empty? }

  def show
    @statuses = load_statuses

    if compact?
      render json: CompactStatusesPresenter.new(statuses: @statuses), serializer: REST::CompactStatusesSerializer
    else
      account_ids = @statuses.filter(&:quote?).map { |status| status.quote.account_id }.uniq

      render json: @statuses, each_serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id), account_relationships: AccountRelationshipsPresenter.new(account_ids, current_user&.account_id), status: account_home_feed.regenerating? ? 206 : 200
    end
  end

  private

  def load_statuses
    cached_personal_statuses
  end

  def cached_personal_statuses
    cache_collection personal_statuses, Status
  end

  def personal_statuses
    personal_feed.get(
      limit_param(DEFAULT_STATUSES_LIMIT),
      params[:max_id],
      params[:since_id],
      params[:min_id],
    )
  end

  def personal_feed
    PersonalFeed.new(current_account)
  end

  def compact?
    truthy_param?(:compact)
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def pagination_params(core_params)
    params.slice(:local, :limit).permit(:local, :limit).merge(core_params)
  end

  def next_path
    api_v1_timelines_home_url pagination_params(max_id: pagination_max_id)
  end

  def prev_path
    api_v1_timelines_home_url pagination_params(min_id: pagination_since_id)
  end

  def pagination_max_id
    @statuses.last.id
  end

  def pagination_since_id
    @statuses.first.id
  end
end
