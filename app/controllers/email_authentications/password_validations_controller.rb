class EmailAuthentications::PasswordValidationsController < ApplicationController
  def create
    auth = EmailAuthentication.new(password: params[:password])
    auth.valid?
    errors = auth.errors[:password]
    render json: errors
  end
end
