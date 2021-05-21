FactoryBot.define do
  factory :treatment_group, class: Experimentation::TreatmentGroup do
    description { Faker::Lorem.unique.word }
    membership_percentage { nil }
    association :experiment, factory: :experiment
  end
end
