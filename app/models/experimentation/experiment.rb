module Experimentation
  class Experiment < ActiveRecord::Base
    has_many :treatment_groups, dependent: :delete_all
    has_many :patients, through: :treatment_groups

    validates :name, presence: true, uniqueness: true
    validates :state, presence: true
    validates :experiment_type, presence: true
    validate :date_range, if: proc { |experiment| experiment.start_date_changed? || experiment.end_date_changed? }
    validate :one_active_experiment_per_type

    enum state: {
      new: "new",
      selecting: "selecting",
      running: "running",
      complete: "complete"
    }, _suffix: true

    enum experiment_type: {
      current_patients: "current_patients",
      stale_patients: "stale_patients"
    }, _prefix: true

    def self.candidate_patients
      Patient.with_hypertension
        .contactable
        .where("age >= ?", 18)
        .includes(treatment_group_memberships: [treatment_group: [:experiment]])
        .where(["experiments.end_date < ? OR experiments.id IS NULL", ExperimentControlService::LAST_EXPERIMENT_BUFFER.ago]).references(:experiment)
    end

    def random_treatment_group
      if evenly_distributed_treatment_groups?
        treatment_groups.sample
      else
        match = treatment_group_percentage_map.find do |(range, group)|
          range.include?(rand(0..99))
        end
        match[1]
      end
    end

    private

    def one_active_experiment_per_type
      existing = self.class.where(state: ["running", "selecting"], experiment_type: experiment_type)
      existing = existing.where("id != ?", id) if persisted?
      if existing.any?
        errors.add(:state, "you cannot have multiple active experiments of type #{experiment_type}")
      end
    end

    def date_range
      if start_date.nil? || end_date.nil?
        errors.add(:date_range, "start date and end date must be set together")
        return
      end
      if start_date > end_date
        errors.add(:date_range, "start date must precede end date")
      end
    end

    # might be wise to memoize this given that we intend to use it on a large number of records
    def evenly_distributed_treatment_groups?
      treatment_groups.pluck(:membership_percentage).compact.empty?
    end

    def treatment_group_percentage_map
      @treatment_group_percentage_map ||= begin
        starting_percent = 0
        percentages = treatment_groups.each_with_object({}) do |group, hsh|
          range = Range.new(starting_percent, starting_percent + group.membership_percentage - 1)
          hsh[range] = group
        end
      end
    end
  end
end
