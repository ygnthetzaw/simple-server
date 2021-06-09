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
        WITH subject_data AS (
          SELECT p.id patient_id, tgm.id patient_identifier, tgm.created_at inclusion_date, p.gender gender, p.age age, p.recorded_at registration_date,
          tg.id treatment_group_id, tg.description treatment_group_description,
          f.name assigned_facility_name, f.facility_type assigned_facility_type, f.state assigned_state,
          f.district assigned_district, mh.diagnosed_with_hypertension hypertensive
          FROM patients p
          INNER JOIN treatment_group_memberships tgm ON tgm.patient_id = p.id
          INNER JOIN treatment_groups tg ON tg.id = tgm.treatment_group_id
          INNER JOIN experiments ON experiments.id = tg.experiment_id
          INNER JOIN medical_histories mh ON mh.patient_id = p.id
          LEFT OUTER JOIN facilities f ON p.assigned_facility_id = f.id
          WHERE experiments.id = :experiment_id
        ),
        followup_visit AS (
            SELECT subject_data.patient_id patient_id,
            date_trunc('day', coalesce(bp.recorded_at, bs.recorded_at, a.device_created_at, pd.device_created_at)) visit_date,
            (date_trunc('day', coalesce(bp.recorded_at, bs.recorded_at, a.device_created_at, pd.device_created_at)) - subject_data.inclusion_date) days_til_visit
            FROM subject_data
            LEFT OUTER JOIN blood_pressures bp ON bp.patient_id = subject_data.patient_id AND bp.recorded_at > subject_data.inclusion_date
            LEFT OUTER JOIN blood_sugars bs ON bs.patient_id = subject_data.patient_id AND bs.recorded_at > subject_data.inclusion_date
            LEFT OUTER JOIN appointments a ON a.patient_id = subject_data.patient_id AND a.device_created_at > subject_data.inclusion_date
            LEFT OUTER JOIN prescription_drugs pd ON pd.patient_id = subject_data.patient_id AND pd.device_created_at > subject_data.inclusion_date
        ),
        bp_recorded_at_visit AS (
          SELECT 1
          FROM followup_visit
          LEFT OUTER JOIN blood_pressures bp ON bp.patient_id = followup_visit.patient_id AND bp.recorded_at > visit_date
        ),
        appointment AS (
          SELECT a.created_at, a.scheduled_date
          FROM subject_data
          LEFT OUTER JOIN appointments a ON a.patient_id = subject_data.patient_id AND a.created_at < subject_data.inclusion_date
          ORDER BY a.created_at DESC
          LIMIT 1
        )
        SELECT
          :experiment_id experiment_id,
          subject_data.patient_identifier,
          subject_data.inclusion_date,
          subject_data.gender,
          subject_data.age,
          subject_data.registration_date,
          subject_data.treatment_group_id,
          subject_data.treatment_group_description,
          subject_data.assigned_facility_name,
          subject_data.assigned_facility_type,
          subject_data.assigned_state,
          subject_data.assigned_district
        FROM subject_data
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