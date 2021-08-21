module Seed
  class ExperimentPatientSeeder
    include ActiveSupport::Benchmarkable

    class << self
      delegate :transaction, to: ActiveRecord::Base
    end

    def self.create_experiment_patient_data(start_date:, end_date:)
      transaction do
        ExperimentSeeder.create_current_experiment(start_date: start_date, end_date: end_date, experiment_name: "Fun time test experiment")
        experiment = Experimentation::Experiment.find_by!(name: "Fun time test experiment")
        user = User.first

        patients = Experimentation::Experiment.candidate_patients.take(10)
        patients.each do |patient|
          date = (start_date..end_date).to_a.sample
          appointment = Appointment.create!(id: SecureRandom.uuid, patient: patient, facility: patient.assigned_facility, user: user, status: "scheduled",
            scheduled_date: date, device_created_at: start_date, device_updated_at: start_date, creation_facility: patient.assigned_facility, appointment_type: "manual")
          group = experiment.treatment_groups.sample
          group.patients << patient
          Experimentation::Runner.schedule_notifications(patient, appointment, group, date)
          notifications = appointment.reload.notifications
          notifications.each do |notification|
            Communication.create!(appointment: appointment, notification: notification, user: user, device_created_at: notification.remind_on, device_updated_at: notification.remind_on, communication_type: "sms")
            TwilioSmsDeliveryDetail.create!(session_id: "abcde", result: "sent", callee_phone_number: patient.latest_mobile_number, delivered_on: notification.remind_on)
            Communication.create!(appointment: appointment, notification: notification, user: user, device_created_at: notification.remind_on, device_updated_at: notification.remind_on, communication_type: "whatsapp")
            TwilioSmsDeliveryDetail.create!(session_id: "abcde", result: "read", callee_phone_number: patient.latest_mobile_number, delivered_on: notification.remind_on)
          end
          days_to_followup = (-2..5).to_a.sample
          followup_date = date + days_to_followup.days
          BloodPressure.create!(id: SecureRandom.uuid, patient: patient, user: user, facility: patient.assigned_facility, systolic: 150, diastolic: 90, device_created_at: followup_date, device_updated_at: followup_date, recorded_at: followup_date)
        end
      end

      def connect_detailables(patient, notification)
        sms = notification.communications.first
        TwilioSmsDeliveryDetail.create!(communication: sms, session_id: "abcde", result: "sent", callee_phone_number: patient.latest_mobile_number, delivered_on: notification.remind_on)
        whatsapp = notification.communications.last
        TwilioSmsDeliveryDetail.create!(communication: whatsapp, session_id: "abcde", result: "read", callee_phone_number: patient.latest_mobile_number, delivered_on: notification.remind_on)
      end
      # someone needs an extra appointment
    end
  end
end
