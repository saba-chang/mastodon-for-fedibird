# frozen_string_literal: true
# == Schema Information
#
# Table name: status_stats
#
#  id                       :bigint(8)        not null, primary key
#  status_id                :bigint(8)        not null
#  replies_count            :bigint(8)        default(0), not null
#  reblogs_count            :bigint(8)        default(0), not null
#  favourites_count         :bigint(8)        default(0), not null
#  emoji_reactions_count    :bigint(8)        default(0), not null
#  emoji_reactions_cache    :string           default(""), not null
#  status_references_count  :bigint(8)        default(0), not null
#  status_referred_by_count :bigint(8)        default(0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class StatusStat < ApplicationRecord
  update_index('statuses') { status }

  belongs_to :status, inverse_of: :status_stat

  after_commit :reset_parent_cache

  private

  def reset_parent_cache
    Rails.cache.delete("statuses/#{status_id}")
  end
end
