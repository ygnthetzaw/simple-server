require "csv"

def subgroup_hash
  {
    "total" => 0,
    "followed_up" => 0,
    "followup_days_total" => 0,
  }
end

def output_results(results)
  results.each_pair do |group_name, group|
    total_patients_in_group = group["all"]["total"]
    puts
    puts "#{group_name} group".upcase

    returned_to_care = ((group["all"]["followed_up"] / (total_patients_in_group).to_f) * 100).round(2)
    puts "Percentage of patients who returned to care: #{returned_to_care}"
    average_days_to_return = (group["all"]["followup_days_total"] / group["all"]["followed_up"].to_f).round(2)
    puts "Average days to return for all patients in group: #{average_days_to_return}"
    puts
    next if group_name == "control"

    puts "Patients who read at least one message"
    read = group["read"]
    percent_read = ((read["total"] / (total_patients_in_group).to_f) * 100).round(2)
    puts "Percentage of all patients in group: #{percent_read}"
    percent_followed_up = ((read["followed_up"] / read["total"].to_f) * 100).round(2)
    puts "Percentage who returned to care: #{percent_followed_up}"
    average_days_to_return = (read["followup_days_total"] / read["followed_up"].to_f).round(2)
    puts "Average days to return: #{average_days_to_return}"
    puts

    puts "Patients who received at least one message"
    delivered = group["delivered"]
    percent_delivered = ((delivered["total"] / (total_patients_in_group).to_f) * 100).round(2)
    puts "Percentage of all patients in group: #{percent_delivered}"
    percent_followed_up = ((delivered["followed_up"] / delivered["total"].to_f) * 100).round(2)
    puts "Percentage who returned to care: #{percent_followed_up}"
    average_days_to_return = (delivered["followup_days_total"] / delivered["followed_up"].to_f).round(2)
    puts "Average days to return: #{average_days_to_return}"
    puts

    puts "Patients who neither read nor received any messages"
    no_messages = group["no_messages"]
    percent_not_received = ((no_messages["total"] / (total_patients_in_group).to_f) * 100).round(2)
    puts "Percentage of all patients in group: #{percent_not_received}"
    percent_followed_up = ((no_messages["followed_up"] / no_messages["total"].to_f) * 100).round(2)
    puts "Percentage who returned to care: #{percent_followed_up}"
    average_days_to_return = (no_messages["followup_days_total"] / no_messages["followed_up"].to_f).round(2)
    puts "Average days to return: #{average_days_to_return}"
  end
end

def process_stale
  stale_file = "/Users/kpethtel/Documents/stale_patient_august_2021.csv"
  table = CSV.parse(File.read(stale_file), headers: true)
  today = Date.today
  ten_days_ago = today - 10
  results = {
    "control" => {
      "all" => subgroup_hash
    },
    "single_notification" => {
      "all" => subgroup_hash,
      "delivered" => subgroup_hash,
      "read" => subgroup_hash,
      "no_messages" => subgroup_hash
    }
  }

  table.each do |row|
    date = Date.parse(row["Experiment Inclusion Date"])
    next unless date < ten_days_ago
    group = row["Treatment Group"]
    days_to_visit = row["Days to visit"]

    results[group]["all"]["total"] += 1

    unless days_to_visit.nil?
      results[group]["all"]["followed_up"] += 1
      results[group]["all"]["followup_days_total"] += days_to_visit.to_i
    end

    unless group == "control"
      # 6 possible messages
      statuses = (1..6).step.map {|message_index| row["Message #{message_index} Status"] }

      if statuses.include?("read")
        results[group]["read"]["total"] += 1
        unless days_to_visit.nil?
          results[group]["read"]["followed_up"] += 1
          results[group]["read"]["followup_days_total"] += days_to_visit.to_i
        end
      end

      if statuses.include?("delivered" ) && !statuses.include?("read")
        results[group]["delivered"]["total"] += 1
        unless days_to_visit.nil?
          results[group]["delivered"]["followed_up"] += 1
          results[group]["delivered"]["followup_days_total"] += days_to_visit.to_i
        end
      end

      if !statuses.include?("delivered") && !statuses.include?("read")
        results[group]["no_messages"]["total"] += 1
        unless days_to_visit.nil?
          results[group]["no_messages"]["followed_up"] += 1
          results[group]["no_messages"]["followup_days_total"] += days_to_visit.to_i
        end
      end
    end
  end

  puts "=== Stale patient experiment ==="

  output_results(results)
end

def process_current
  current_file = "/Users/kpethtel/Documents/current_patient_august_2021.csv"
  table = CSV.parse(File.read(current_file), headers: true)
  today = Date.today
  ten_days_ago = today - 10
  results = {
    "control" => {
      "all" => subgroup_hash
    },
    "single_notification" => {
      "all" => subgroup_hash,
      "delivered" => subgroup_hash,
      "read" => subgroup_hash,
      "no_messages" => subgroup_hash
    },
    "cascade" => {
      "all" => subgroup_hash,
      "delivered" => subgroup_hash,
      "read" => subgroup_hash,
      "no_messages" => subgroup_hash
    }
  }

  table.each do |row|
    group = row["Treatment Group"]
    # five possible followups
    (1..5).step do |i|
      next unless row["Experiment Appointment #{i} Date"]
      date = Date.parse(row["Experiment Appointment #{i} Date"])
      next unless date < ten_days_ago
      days_to_visit = row["Days to visit #{i}"]

      results[group]["all"]["total"] += 1

      unless days_to_visit.nil?
        results[group]["all"]["followed_up"] += 1
        results[group]["all"]["followup_days_total"] += days_to_visit.to_i
      end

      unless group == "control"
        # 12 possible messages
        statuses = (1..12).step.map {|message_index| row["Message #{message_index} Status"] }

        if statuses.include?("read")
          results[group]["read"]["total"] += 1
          unless days_to_visit.nil?
            results[group]["read"]["followed_up"] += 1
            results[group]["read"]["followup_days_total"] += days_to_visit.to_i
          end
        end

        if statuses.include?("delivered") && !statuses.include?("read")
          results[group]["delivered"]["total"] += 1
          unless days_to_visit.nil?
            results[group]["delivered"]["followed_up"] += 1
            results[group]["delivered"]["followup_days_total"] += days_to_visit.to_i
          end
        end

        if !statuses.include?("delivered") && !statuses.include?("read")
          results[group]["no_messages"]["total"] += 1
          unless days_to_visit.nil?
            results[group]["no_messages"]["followed_up"] += 1
            results[group]["no_messages"]["followup_days_total"] += days_to_visit.to_i
          end
        end
      end
    end
  end

  puts "=== Current patient experiment ==="

  output_results(results)
end

process_current
puts
process_stale