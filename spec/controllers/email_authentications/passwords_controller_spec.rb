require "rails_helper"

RSpec.describe EmailAuthentications::PasswordsController, type: :request do

  describe "password_validation" do
    it "works" do
      post "/email_authentications/validate_password", params: {password: "Password1"}
      body = JSON.parse(response.body)
      expected_errors = ["is too short (minimum is 10 characters)", "must be between 10 and 128 characters"]
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to match_array(expected_errors)
    end
  end

end