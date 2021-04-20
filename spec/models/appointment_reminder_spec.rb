require "rails_helper"

describe AppointmentReminder, type: :model do
  describe "associations" do
    it { should belong_to(:appointment) }
    it { should belong_to(:patient) }
    it { should belong_to(:experiment).optional }
    it { should belong_to(:reminder_template).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:remind_on) }
    it { should validate_presence_of(:message) }
  end

  describe "#next_communication_type" do
    let(:appointment_reminder) { create(:appointment_reminder) }

    context "in India" do
      it "returns missed_visit_whatsapp_reminder if it has no whatsapp communications" do
        expect(appointment_reminder.next_communication_type).to eq("missed_visit_whatsapp_reminder")
      end

      it "returns missed_visit_sms_reminder if it has a whatsapp communication but no sms communication" do
        create(:communication, communication_type: "missed_visit_whatsapp_reminder", appointment_reminder: appointment_reminder)
        expect(appointment_reminder.next_communication_type).to eq("missed_visit_sms_reminder")
      end

      it "returns nil if it has both a whatsapp and sms communication" do
        create(:communication, communication_type: "missed_visit_whatsapp_reminder", appointment_reminder: appointment_reminder)
        create(:communication, communication_type: "missed_visit_sms_reminder", appointment_reminder: appointment_reminder)
        expect(appointment_reminder.next_communication_type).to eq(nil)
      end
    end

    context "outside of India" do
      before :each do
        allow(CountryConfig).to receive(:current).and_return(CountryConfig.for(:BD))
      end

      it "returns missed_visit_sms_reminder if it has no sms communication" do
        expect(appointment_reminder.next_communication_type).to eq("missed_visit_sms_reminder")
      end

      it "returns nil if it has an sms communication" do
        create(:communication, communication_type: "missed_visit_sms_reminder", appointment_reminder: appointment_reminder)
        expect(appointment_reminder.next_communication_type).to eq(nil)
      end
    end
  end
end
