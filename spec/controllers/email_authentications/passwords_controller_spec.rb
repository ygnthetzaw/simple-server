require "rails_helper"

RSpec.describe EmailAuthentications::PasswordsController, type: :request do

  describe "password_validation" do
    it "works" do
      post "/email_authentications/validate_password", params: {password: "Password1"}
      expect(response.status).to eq 200
    end
  end

end