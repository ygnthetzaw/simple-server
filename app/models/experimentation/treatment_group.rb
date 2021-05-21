module Experimentation
  class TreatmentGroup < ActiveRecord::Base
    belongs_to :experiment
    has_many :reminder_templates, dependent: :delete_all
    has_many :treatment_group_memberships
    has_many :patients, through: :treatment_group_memberships

    validates :description, presence: true, uniqueness: {scope: :experiment_id}
    validates :membership_percentage, numericality: { greater_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
    validate :membership_percentage_under_100, if: :membership_percentage_changed?

    private

    def membership_percentage_under_100
      membership_percentages = experiment.treatment_groups.pluck(:membership_percentage)
      if membership_percentages.sum > 100
        errors.add(:membership_percentage, "membership percentages within an experiment can't exceed 100")
      end
    end
  end
end
