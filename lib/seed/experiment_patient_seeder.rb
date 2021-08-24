module Seed
  class ExperimentPatientSeeder
    include ActiveSupport::Benchmarkable

    class << self
      delegate :transaction, to: ActiveRecord::Base

      def create_experiment_patient_data(start_date:, end_date:)
        transaction do
          experiment_name = "Test123"
          Seed::ExperimentSeeder.create_current_experiment(start_date: start_date, end_date: end_date, experiment_name: experiment_name)
          experiment = Experimentation::Experiment.find_by!(name: experiment_name)
          user = User.first
          patients = Experimentation::Experiment.candidate_patients.take(10)
          frequent_flyer = patients.first # give someone two appointments

          patients.each do |patient|
            group = add_to_treatment_group(patient, experiment)
            appointments = []

            if patient == frequent_flyer
              date1 = experiment.start_date + 1.days
              date2 = date1 + 11.days
              appointments << create_appointment(patient, experiment, user, date1)
              appointments << create_appointment(patient, experiment, user, date2)
            else
              date = (start_date.to_date..end_date.to_date).to_a.sample
              appointments << create_appointment(patient, experiment, user, date)
            end

            appointments.each do |appointment|
              date = appointment.scheduled_date
              Experimentation::Runner.schedule_notifications(patient, appointment, group, date)
              notifications = appointment.reload.notifications
              create_communications(patient, appointment, user, notifications)
            end

            days_to_followup = (-2..10).to_a.sample
            followup_date = appointments.first.scheduled_date + days_to_followup.days
            BloodPressure.create!(id: SecureRandom.uuid, patient: patient, user: user, facility: patient.assigned_facility, systolic: 150, diastolic: 90, device_created_at: followup_date, device_updated_at: followup_date, recorded_at: followup_date)
          end
        end
      end

      def create_appointment(patient, experiment, user, date)
        before_experiment = experiment.start_date - 1.week
        Appointment.create!(id: SecureRandom.uuid, patient: patient, facility: patient.assigned_facility, user: user, status: "scheduled", scheduled_date: date,
                            device_created_at: before_experiment, device_updated_at: before_experiment, creation_facility: patient.assigned_facility, appointment_type: "manual")
      end

      def add_to_treatment_group(patient, experiment)
        group = experiment.treatment_groups.sample
        Experimentation::TreatmentGroupMembership.create!(patient: patient, treatment_group: group, created_at: experiment.start_date)
        group
      end

      def create_communications(patient, appointment, user, notifications)
        notifications.each do |notification|
          communication = Communication.create!(appointment: appointment, notification: notification, user: user, device_created_at: notification.remind_on, device_updated_at: notification.remind_on, communication_type: "sms")
          TwilioSmsDeliveryDetail.create!(communication: communication, session_id: "abcde", result: "sent", callee_phone_number: patient.latest_mobile_number, delivered_on: notification.remind_on)
          communication = Communication.create!(appointment: appointment, notification: notification, user: user, device_created_at: notification.remind_on, device_updated_at: notification.remind_on, communication_type: "whatsapp")
          TwilioSmsDeliveryDetail.create!(communication: communication, session_id: "abcde", result: "read", callee_phone_number: patient.latest_mobile_number, delivered_on: notification.remind_on)
        end
      end
    end
  end
end
