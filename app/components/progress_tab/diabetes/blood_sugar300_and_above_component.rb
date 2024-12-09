# frozen_string_literal: true

class ProgressTab::Diabetes::BloodSugar300AndAboveComponent < ApplicationComponent
  include AssetsHelper
  include FlipperHelper

  attr_reader :uncontrolled_rates, :uncontrolled, :adjusted_patients, :period_info, :region

  def initialize(uncontrolled_rates:, uncontrolled:, adjusted_patients:, period_info:, region:, use_who_standard: nil)
    @uncontrolled_rates = uncontrolled_rates
    @uncontrolled = uncontrolled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
    @use_who_standard = resolve_use_who_standard(use_who_standard)

    set_locale_values
  end

  private

  def set_locale_values
    if @use_who_standard
      @uncontrolled_threshold_long = t("bs_over_200_copy.bs_over_300.numerator_dm_fbs")
      @uncontrolled_threshold_short = t("bs_over_200_copy.bs_over_300.title_dm_fbs")
      @uncontrolled_threshold_bar = t("bs_over_200_copy.bs_over_300.title_dm_fbs")
      @subtitle_text = t(
        "bs_over_200_copy.bs_over_300.reports_card_subtitle_fbs",
        region_name: @region.name,
        diagnosis: "Diabetes",
        controlled_threshold: @uncontrolled_threshold_long
      )
      @numerator_text = t("bs_over_200_copy.bs_over_300.numerator_dm_fbs")
    else
      @uncontrolled_threshold_long = t("bs_over_200_copy.bs_over_300.numerator_dm")
      @uncontrolled_threshold_short = t("bs_over_200_copy.bs_over_300.title")
      @uncontrolled_threshold_bar = t("bs_over_200_copy.bs_over_300.report_card_lower_bar")
      @subtitle_text = t(
        "bs_over_200_copy.bs_over_300.reports_card_subtitle",
        region_name: @region.name,
        diagnosis: "Diabetes",
        controlled_threshold: @uncontrolled_threshold_long
      )
      @numerator_text = t("bs_over_200_copy.bs_over_300.numerator")
    end

    @denominator_text = t(
      "progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.denominator",
      facility_name: @region.name,
      diagnosis: "Diabetes"
    )
  end
end
