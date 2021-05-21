require "rails_helper"

RSpec.describe Experimentation::Experiment, type: :model do
  let(:experiment) { create(:experiment) }

  describe "associations" do
    it { should have_many(:treatment_groups) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { experiment.should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:experiment_type) }

    it "there can only be one active experiment of a particular type at a time" do
      create(:experiment, state: :running, experiment_type: "current_patients")
      create(:experiment, state: :selecting, experiment_type: "stale_patients")

      experiment_3 = build(:experiment, state: :running, experiment_type: "current_patients")
      expect(experiment_3).to be_invalid

      experiment_4 = build(:experiment, state: :running, experiment_type: "stale_patients")
      expect(experiment_4).to be_invalid
    end

    it "can only be updated to a complete and valid date range" do
      experiment = create(:experiment)
      experiment.update(start_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: nil, end_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: Date.today + 3.days, end_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: Date.today, end_date: Date.today + 3.days)
      expect(experiment).to be_valid
    end
  end

  describe "#random_treatment_group" do
    context "when treatment groups do not specify membership_perentages" do
      it "returns a treatment group from the experiment" do
        experiment = create(:experiment, :with_treatment_group)

        expect(experiment.random_treatment_group).to eq(experiment.treatment_groups.first)
      end
    end

    context "when treatment groups do specify membership_percentages" do
      it "returns a treatment group from the experiment" do
        experiment = create(:experiment)
        treatment_group = create(:treatment_group, experiment: experiment, membership_percentage: 100)

        expect(experiment.random_treatment_group).to eq(treatment_group)
      end
    end
  end
end
