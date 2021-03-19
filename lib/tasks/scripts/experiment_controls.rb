module ExperimentControls
  # bash: rake start_active_patients_experiment[20]
  # zsh: rake start_active_patients_experiment\[20\]
  def self.start_active_patient_experiment(percentage_of_patients)
    eligibility_start = Date.current
    eligibility_end = Date.current + 30.days
    eligible = self.patient_pool
      .joins(:appointments)
      .where("appointments.status = ?", "scheduled")
      .where("appointments.scheduled_date BETWEEN ? AND ?", eligibility_start, eligibility_end)
      .order(Arel.sql('random()')) # not working because the phone number ordering from contactable is overiding it
    experiment_patient_count = (0.01 * percentage_of_patients * eligible.length).round
    experiment_patients = eligible.take(experiment_patient_count)
    experiment_patients.each do |patient|
      Flipper.enable(:experiment, patient)
    end
  end

  def self.end_active_patient_experiment
    Flipper.remove(:experiment)
  end

  def self.start_inactive_patient_experiment(id, max_patients=300_000)
    experiment = Experiment.find(id)
    eligibility_start = (Date.current - 365.days).beginning_of_day
    eligibility_end = (Date.current - 35.days).end_of_day
    eligible_patients = self.patient_pool
      .joins(:appointments)
      .where("appointments.status = ?", "scheduled")
      .where("appointments.scheduled_date BETWEEN ? AND ?", eligibility_start, eligibility_end)
      .limit(max_patients)
      .order(Arel.sql('random()')) # not working
    date = Date.current
    30.times do
      schedule_patients = eligible_patients.take(10_000)
      break if schedule_patients.empty?
      schedule_patients.each do |patient|
        AppointmentReminder.new(
          appointment_id: patient.appointments.last&.id,
          experiment_id: experiment.id,
          experiment_group: experiment.bucket_for_patient(patient.id),
          status: "scheduled",
          remind_on: date
        )
      end
      date = date += 1.day
    end
  end

  protected
  def self.patient_pool
    Patient.from(Patient.with_hypertension, :patients).contactable.where("age >= ?", 18)
  end
end