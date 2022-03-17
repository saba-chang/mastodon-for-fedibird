# frozen_string_literal: true

class StatusReferenceValidator < ActiveModel::Validator
  LIMIT = 100

  def validate(reference)
    reference.errors.add(:name, I18n.t('status_references.errors.limit')) if reference.status.reference_relationships.count >= LIMIT && reference.status.account.local?
    reference.errors.add(:name, I18n.t('status_references.errors.visibility')) unless reference.target_status.distributable? || reference.target_status.private_visibility?
  end
end
