module Experimentation
  class Export
    require "csv"

    EXPANDABLE_COLUMNS = ["Followups", "Communications", "Appointments", "Blood Pressures"].freeze
    FOLLOWUP_START = 3.days
    FOLLOWUP_CUTOFF = 10.days

    attr_reader :experiment, :patient_data_aggregate, :query_date_range, :messaging_offset_before_appointment, :experiment_run_date

    def initialize(experiment)
      @experiment = experiment
      unless experiment.experiment_type.in?(["current_patients", "stale_patients"])
        raise ArgumentError, "Experiment type #{experiment.experiment_type} not supported"
      end

      @patient_data_aggregate = []

      @messaging_offset_before_appointment = experiment.reminder_templates.pluck(:remind_on_in_days).min
      start_date = experiment.start_date - 1.year
      end_date = experiment.end_date + FOLLOWUP_CUTOFF
      @query_date_range = start_date..end_date
      @experiment_run_date = experiment.start_date - messaging_offset_before_appointment
      aggregate_data
    end

    def write_csv
      file_location = "/tmp/" + experiment.name.downcase.tr(" ", "_") + ".csv"
      File.write(file_location, csv_data)
    end

    private

    def csv_data
      CSV.generate(headers: true) do |csv|
        csv << headers
        patient_data_aggregate.each do |patient_data|
          EXPANDABLE_COLUMNS.each do |column|
            patient_data[column].each { |column_data| patient_data.merge!(column_data) }
          end
          csv << patient_data
        end
      end
    end

    def aggregate_data
      experiment.treatment_groups.each do |group|
        group.patients.each do |patient|
          notifications = patient.notifications.where(experiment_id: experiment.id).order(:remind_on)
          tgm = patient.treatment_group_memberships.find_by(treatment_group_id: group.id)
          assigned_facility = patient.assigned_facility
          followups = if experiment.experiment_type == "current_patients"
            appointment = current_experiment_subject_appointment(patient, group, notifications)
            # we have decided to exclude patients who received notifications for multiple appointments during the experiment
            # this was fewer than 40 patients per treatment group in the first experiment
            # this should not be needed for subsequent experiments due to changes in design
            next if appointment.nil?
            current_patient_followups(patient, appointment)
          else
            stale_patient_followups(patient, tgm)
          end

          patient_data_aggregate << {
            "Experiment Name" => experiment.name,
            "Treatment Group" => group.description,
            "Experiment Inclusion Date" => tgm.created_at.to_date,
            "Followups" => followups,
            "Communications" => communications(notifications),
            "Blood Pressures" => blood_pressure_history(patient),
            "Patient Gender" => patient.gender,
            "Patient Age" => patient.age,
            "Patient Risk Level" => patient.high_risk? ? "High" : "Normal",
            "Assigned Facility Name" => assigned_facility&.name,
            "Assigned Facility Type" => assigned_facility&.facility_type,
            "Assigned Facility State" => assigned_facility&.state,
            "Assigned Facility District" => assigned_facility&.district,
            "Assigned Facility Block" => assigned_facility&.block,
            "Patient Registration Date" => patient.device_created_at.to_date,
            "Patient Id" => tgm.id
          }
        end
      end
    end

    def current_experiment_subject_appointment(patient, group, notifications)
      appointments = notifications.map(&:subject).uniq

      return nil if appointments.count > 1
      return appointments.first unless group.description == "control"
      find_control_appointment(patient)
    end

    # this is very janky. we decided to remove the appointment history but have to have some way of knowing what the first appointment
    # that should have been included in the experiment was. We have found a bug that was creating large numbers of appointments
    # and marking most of them "visited", thus the convoluted logic
    def find_control_appointment(patient)
      appointments = patient.appointments
        .where("scheduled_date >= ?", experiment.start_date)
        .where("device_created_at < ?", experiment_run_date).order(:scheduled_date)
      first_unvisited = appointments.where(status: "scheduled").where("updated_at < ?", experiment_run_date).first
      first_visited = appointments.where(status: "visited").where("updated_at > ?", experiment_run_date).first
      if first_visited.nil? && first_unvisited.nil?
        appointments.first # maybe it was cancelled?
      elsif first_visited.nil?
        first_unvisited
      elsif first_unvisited.nil?
        first_visited
      else
        [first_visited, first_unvisited].sort{|a,b| a.scheduled_date <=> b.scheduled_date }.first
      end
    end

    def communications(notifications)
      notifications.each_with_object([]) do |notification, communication_results|
        communication_results << communications_for_notification(notification)
      end
    end

    def communications_for_notification(notification)
      aggregate_communications = []
      ordered_communications = notification.communications.order(:created_at)
      ordered_communications.each_with_index do |comm, index|
        aggregate_communications << {
          "Message #{index} Type" => comm.communication_type,
          "Message #{index} Date Sent" => comm.detailable&.delivered_on&.to_date,
          "Message #{index} Status" => comm.detailable&.result,
          "Message #{index} Text Identifier" => notification.message
        }
      end
    end

    # this is fuzzy in the first wave but should become much clearer when we switch to daily inclusion
    # anyone with a nil expected return date should probably just be excluded
    def current_patient_followups(patient, appointment)
      expected_return_date = appointment.scheduled_date.to_date
      followup_date_range = ((appointment.scheduled_date - messaging_offset_before_appointment)..(appointment.scheduled_date + FOLLOWUP_CUTOFF))
      followup_date = patient.blood_pressures.where(device_created_at: followup_date_range).order(:device_created_at).first&.device_created_at&.to_date
      days_to_followup = followup_date.nil? ? nil : (followup_date - expected_return_date).to_i
      {
        "Expected Return Date" => appointment&.scheduled_date&.to_date,
        "Followup Date" => followup_date,
        "Days to visit" => days_to_followup
      }
    end

    def stale_patient_followups(patient, tgm)
      last_appointment = patient.appointments.where("device_created_at < ?", tgm.created_at).order(:start_date).last
      date_added = tgm.created_at.to_date
      followup_date_range = (date_added..(date_added + FOLLOWUP_CUTOFF))
      followup_date = patient.blood_pressures.where(device_created_at: followup_date_range).order(:device_created_at).first&.device_created_at&.to_date
      days_to_followup = followup_date.nil? ? nil : (followup_date - date_added).to_i
      {
        "Last Visited" => last_appointment.device_created_at.to_date,
        "Followup Date" => followup_date,
        "Days to visit" => days_to_followup
      }
    end

    def blood_pressure_history(patient)
      bp_dates = patient.blood_pressures.where(device_created_at: query_date_range).order(:device_created_at).pluck(:device_created_at).map(&:to_date).uniq
      bp_dates.each_with_index.map do |bp_date, index|
        adjusted_index = index + 1
        {"Blood Pressure #{adjusted_index} Date" => bp_date}
      end
    end

    def headers
      first_entry = patient_data_aggregate.first
      keys = first_entry.keys
      keys.map do |key|
        case first_entry[key]
        when Array
          largest_entry = patient_data_aggregate.max { |a, b| a[key].length <=> b[key].length }
          largest_entry[key].map(&:keys)
        when Hash
          first_entry[key].keys
        else
          key
        end
      end.flatten
    end
  end
end
