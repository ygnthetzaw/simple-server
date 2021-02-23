PasswordValidation = function() {
  const DebounceTimer = 500;
  this.timer = null;
  this.passwordInput = $("#password");
  this.response = null;

  this.addPasswordListener = function() {
    console.log("FIELD: ", this.passwordInput)
    this.passwordInput.on("input", this.handlePasswordInput.bind(this));
  }

  this.setTimer = function() {
    console.log("STARTING TIMER")
    this.cancelTimer()
    this.timer = setTimeout(this.validatePassword.bind(this), DebounceTimer);
  }

  this.cancelTimer = function() {
    console.log("CANCELING TIMER")
    if (!this.timer) return;
    clearTimeout(this.timer);
    this.timer = null;
  }

  this.handlePasswordInput = function() {
    console.log("CHANGE", this.passwordInput.val());
    this.setTimer();
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
      data: {"password": this.passwordInput.val()}
    }).done(function(data, status){
      console.log(status)
      console.log(data)
      this.timer = null;
      if (status === "success") {
        this.response = data["errors"];
      } else {
        this.response = null;
      }
    });
  }
}