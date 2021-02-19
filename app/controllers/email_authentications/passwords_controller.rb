class EmailAuthentications::PasswordsController < ApplicationController

  def validate_password
    auth = EmailAuthentication.new(password: params[:password])
    auth.valid?
    errors = auth.errors[:password]
    render json: to_response(errors)
  end
end
