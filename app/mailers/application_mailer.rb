class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAILERS_FROM"].presence || "help@simple.innosoftmm.com"
  layout "mailer"

  helper SimpleServerEnvHelper
end
