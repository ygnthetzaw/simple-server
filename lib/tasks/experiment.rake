require "tasks/scripts/experiment_controls"

desc "start a new experiment on active patients"
task :start_active_patients_experiment, [:percentage_of_patients] => :environment do |_t, args|
  percentage = Integer(args[:percentage_of_patients])
  ExperimentControls.start_active_patient_experiment(percentage)
end

desc "end experiment on active patients"
task :end_experiment => :environment do |_t, args|
  ExperimentControls.end_active_patient_experiment
end

desc "start a new experiment on inactive patients"
task :start_inactive_patients_experiment, [:id, :max_patients] => :environment do |_t, args|
  id = args[:id]
  max_patients = args[:max_patients]
  ExperimentControls.start_inactive_patient_experiment
end

