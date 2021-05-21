class AddMembershipPercentageToTreatmentGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :treatment_groups, :membership_percentage, :integer, null: true
  end
end
