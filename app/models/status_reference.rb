# frozen_string_literal: true

# == Schema Information
#
# Table name: status_references
#
#  id               :bigint(8)        not null, primary key
#  status_id        :bigint(8)        not null
#  target_status_id :bigint(8)        not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class StatusReference < ApplicationRecord
  include Paginable

  update_index('statuses', :target_status)

  belongs_to :status
  belongs_to :target_status, class_name: 'Status'

  has_one :notification, as: :activity, dependent: :destroy

  validates :target_status_id, uniqueness: { scope: :status_id }
  validates_with StatusReferenceValidator

  after_create :increment_cache_counters
  after_destroy :decrement_cache_counters

  private

  def increment_cache_counters
    status&.increment_count!(:status_references_count)
    target_status&.increment_count!(:status_referred_by_count)
  end

  def decrement_cache_counters
    status&.decrement_count!(:status_references_count)
    target_status&.decrement_count!(:status_referred_by_count)
  end
end
