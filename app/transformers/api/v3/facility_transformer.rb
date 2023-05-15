class Api::V3::FacilityTransformer
  class << self
    def to_response(facility)
      facility.as_json
        .except("enable_diabetes_management",
          "monthly_estimated_opd_load",
          "enable_teleconsultation",
          "teleconsultation_phone_number",
          "teleconsultation_isd_code",
          "teleconsultation_phone_numbers",
          "organization_name",
          "facility_group_name",
          "enable_monthly_screening_reports",
          "enable_monthly_supplies_reports")
        .merge(config: {enable_diabetes_management: facility.enable_diabetes_management,
                        enable_teleconsultation: facility.enable_teleconsultation,
                        enable_monthly_screening_reports: facility.enable_monthly_screening_reports,
                        enable_monthly_supplies_reports: facility.enable_monthly_supplies_reports},
          protocol_id: facility.protocol.try(:id))
    end
  end
end
