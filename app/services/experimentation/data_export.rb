module Experimentation
  class DataExport

    HEADERS = ["Test", "Bucket", "Bucket name", "Experiment Inclusion Date", "Appointment Creation Date",
      	"Appointment Date",	"Patient Visit Date",	"Days to visit", "Message 1 Type", "Message 1 Sent", "Message 1 Received", "Message 2 Type", "Message 2 Sent",
        "Message 2 Status",	"Message 3 Type",	"Message 3 Sent",	"Message 3 Received",	"BP recorded at visit",	"Patient Gender",	"Patient Age",
        "Patient risk level",	"Diagnosed HTN", "Patient has phone number", "Patient Visited Facility", "Visited Facility Type",	"Visited Facility State",
        "Visited Facility District", "Visited Facility Block", "Patient Assigned Facility",	"Assigned Facility Type",	"Assigned Facility State",
        "Assigned Facility District", "Assigned Facility Block", "Prior visit 1",	"Prior visit 2", "Prior visit 12", "Call made 1",	"Call made 2",
        "Call made 3", "Patient registration date",	"Patient ID"]

    attr_reader :experiment

    def initialize(name)
      @experiment = Experimentation::Experiment.find_by!(name: name)
    end

    def result
      query.results
    end

    private

=begin
Experiment: id,
Patient: gender, age, assigned_facility_id, recorded_at,
TreatmentGroup: id, name
Appointment: created_at, schedule_date
TreatmentGroupMembership: id, creation date
Notification: used to get all message types and statuses
Medical history: patient risk level, diagnosed HTN,
Facility (might get interesting): name, type, state, district, block,
Assigned facility: name, type, state, district, block


Patient visit date is the first "visit" after inclusion in experiment or maybe after notifications send
Days to visit is ^ - first notification date
BP recorded at visit: does the visit include a bp?
Shouldn't "patient has phone number" be true for all?

Prior visits
Prior calls
=end

    def query
      GitHub::SQL.new(<<~SQL, parameters)
        WITH experiment_subjects AS (
          SELECT tgm.id AS patient_identifier, patients.gender AS gender, patients.age AS age,
          tg.id AS treatment_group_id, tg.description AS treatment_group_description
          FROM patients
          INNER JOIN treatment_group_memberships tgm ON tgm.patient_id = patients.id
          INNER JOIN treatment_groups tg ON tg.id = tgm.treatment_group_id
          INNER JOIN experiments ON experiments.id = tg.experiment_id
          WHERE experiments.id = :experiment_id
        )
        SELECT
          experiment_subjects.patient_identifier,
          experiment_subjects.gender,
          experiment_subjects.treatment_group_id,
          experiment_subjects.treatment_group_description
        FROM experiment_subjects
      SQL
    end

    def parameters
      {
        experiment_id: experiment.id,
        experiment_start: experiment.start_date.in_time_zone(Rails.application.config.country[:time_zone]).beginning_of_day,
        experiment_end: experiment.end_date.in_time_zone(Rails.application.config.country[:time_zone]).end_of_day
      }
    end

  end
end