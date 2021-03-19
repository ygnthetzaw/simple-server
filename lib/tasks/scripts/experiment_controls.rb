module ExperimentControls
  def self.start_active_patient_experiment(percentage_of_patients)
    eligible = Patient.from(Patient.with_hypertension, :patients).contactable.where("age >= ?", 18)
    experiment_patient_count = (0.01 * percentage_of_patients * eligible.length).round
    experiment_patients = eligible.take(experiment_patient_count)
    experiment_patients.each do |patient|
      Flipper.enable(:experiment, patient)
    end
  end

  def self.end_active_patient_experiment
    Flipper.remove(:experiment)
  end

  def self.start_inactive_patient_experiment(id, max_patients)
  end
end