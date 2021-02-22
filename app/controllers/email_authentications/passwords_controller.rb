class EmailAuthentications::PasswordsController < ActionController::Base

  def validate_password
    auth = EmailAuthentication.new(password: params[:password])
    auth.valid?
    errors = auth.errors[:password]
    render json: errors
  end
end
