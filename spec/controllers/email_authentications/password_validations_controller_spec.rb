require "rails_helper"

RSpec.describe EmailAuthentications::PasswordValidationsController, type: :request do

  describe "create" do
    it "works" do
      post "/email_authentications/validate", params: {password: "Password1"}
      body = JSON.parse(response.body)
      expected_errors = ["is too short (minimum is 10 characters)", "must be between 10 and 128 characters"]
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to match_array(expected_errors)
    end
  end

end