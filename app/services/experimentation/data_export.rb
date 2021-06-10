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

Problems: 
- need a way of finding just the first visit. It'll also be interesting to find out if notifications were properly cancelled after they came in. This was all dependent on something the android team said.
- need to figure out the visit facility
- appointment should be based on appointment facility

QUESTIONS:
- should follow up visit date always be their next visit after inclusion?

=end

    def query
      GitHub::SQL.new(<<~SQL, parameters)
        SELECT
          DISTINCT ON (subject_data.patient_identifier)
          subject_data.patient_identifier,
          assigned_facility_id,
          visited_at.as_date,
          (
            SELECT 1 FROM blood_pressures bp
            WHERE bp.patient_id = subject_data.patient_id AND
            date_trunc('day', bp.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) = visited_at.as_date
          ) bp_recorded_at_visit
        FROM
          (
            SELECT
              p.id patient_id, tgm.id patient_identifier,
              date_trunc('day', tgm.created_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) AS inclusion_date,
              p.gender, p.age, p.recorded_at registration_date,
              tg.id treatment_group_id, tg.description treatment_group_description,
              mh.diagnosed_with_hypertension hypertensive, p.assigned_facility_id
            FROM patients p
            INNER JOIN treatment_group_memberships tgm ON tgm.patient_id = p.id
            INNER JOIN treatment_groups tg ON tg.id = tgm.treatment_group_id
            INNER JOIN experiments ON experiments.id = tg.experiment_id
            INNER JOIN medical_histories mh ON mh.patient_id = p.id
            WHERE experiments.id = :experiment_id
          ) subject_data
        LEFT JOIN LATERAL (
          SELECT
            af.id, af.name assigned_facility_name, af.facility_type assigned_facility_type, af.state assigned_state
          FROM facilities af
          WHERE af.id = subject_data.assigned_facility_id
        ) assigned_facility_id ON true
        LEFT JOIN LATERAL (
          SELECT encountered_on, facility_id
          FROM encounters
          WHERE patient_id = subject_data.patient_id
            AND (encountered_on AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) >= subject_data.inclusion_date
            AND deleted_at is null
          ORDER BY encountered_on ASC
          LIMIT 1
        ) e ON true
        LEFT JOIN LATERAL (
            SELECT device_created_at, facility_id
            FROM prescription_drugs
            WHERE patient_id = subject_data.patient_id
              AND date_trunc('day', device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) >= subject_data.inclusion_date
              AND deleted_at is null
            ORDER BY device_created_at ASC
            LIMIT 1
        ) pd ON true
        LEFT JOIN LATERAL (
            SELECT device_created_at, facility_id
            FROM appointments
            WHERE patient_id = subject_data.patient_id
              AND date_trunc('day', device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) >= subject_data.inclusion_date
              AND deleted_at is null
            ORDER BY device_created_at ASC
            LIMIT 1
        ) app ON true
        LEFT JOIN LATERAL (
          SELECT greatest(e.encountered_on, pd.device_created_at, app.device_created_at) AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' as_date
        ) visited_at ON true
        LEFT JOIN LATERAL (
          SELECT a.scheduled_date
          FROM appointments
          WHERE a.patient_id = subject_data.patient_id AND a.created_at < subject_data.inclusion_date
          ORDER BY a.created_at DESC
          LIMIT 1
        ) previous_appointment_date
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