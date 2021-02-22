PasswordValidation = function() {
  this.timer = null;
  this.timerDuration = 500;
  this.passwordField = $("#password");

  this.addPasswordListener = function() {
    console.log("FIELD: ", this.passwordField)
    this.passwordField.on("input", this.handlePasswordInput.bind(this));
  }

  this.setTimer = function() {
    console.log("STARTING TIMER")
    this.cancelTimer()
    this.timer = setTimeout(this.validatePassword.bind(this), this.timerDuration);
  }

  this.handlePasswordInput = function() {
    console.log("CHANGE", this.passwordField.val());
    this.setTimer();
  }

  this.cancelTimer = function() {
    console.log("CANCELING TIMER")
    if (!this.timer) return
    clearTimeout(this.timer);
    this.timer = null;
  }

  this.validatePassword = function() {
    console.log("MAKING REQUEST")

    const token = $('meta[name=csrf-token]').attr('content')
    const url = "http://localhost:3000/email_authentications/validate"
    $.ajax({
      type: "POST",
      url: url,
      headers: {
        "X-CSRF-Token": token
      },
      data: {"password": this.passwordField.val()}
    }).done(function(data, status){
      console.log(status)
      console.log(data)
      this.timer = null;
    });
  }
}