PasswordValidation = function() {
  const DebounceTimeout = 500;
  const DefaultResult = {length: false, lower: false, upper: false, number: false}

  this.initialize = function() {
    this.timer = null;
    this.result = DefaultResult;
    this.passwordInput = $("#password");
    this.passwordInput.on("input", this.handlePasswordInput);
  }

  this.handlePasswordInput = () => {
    console.log("CHANGE", this.passwordInput.val());
    this.setTimer();
  }

  this.setTimer = function() {
    console.log("STARTING TIMER")
    this.cancelTimer();
    this.timer = setTimeout(this.validatePassword, DebounceTimeout);
  }

  this.cancelTimer = function() {
    console.log("CANCELING TIMER")
    if (!this.timer) return;
    clearTimeout(this.timer);
    this.timer = null;
  }

  this.validatePassword = () => {
    console.log("MAKING REQUEST")
    const token = $("meta[name=csrf-token]").attr("content")
    const url = "http://localhost:3000/email_authentications/validate"
    const password = this.passwordInput.val();

    $.ajax({
      type: "POST",
      url: url,
      headers: {
        "X-CSRF-Token": token
      },
      data: {"password": password}
    }).done((data, status) => {
      console.log(status)
      console.log(data)
      this.timer = null;
      if (status === "success") {
        this.updateResults(data["errors"]);
      } else {
        this.result = DefaultResult;
      }
      this.updateChecklist();
    });

    this.updateResults = function(response) {
      this.result["length"] = response.includes("must be between 10 and 128 characters");
      this.result["lower"] = response.includes("must contain at least one lower case letter");
      this.result["upper"] = response.includes("must contain at least one upper case letter");
      this.result["number"] = response.includes("must contain at least one number");
    }

    this.updateChecklist = function() {
      this.result["length"] ? this.uncheckItem("length") : this.checkItem("length")
      this.result["lower"]? this.uncheckItem("lower") : this.checkItem("lower")
      this.result["upper"] ? this.uncheckItem("upper") : this.checkItem("upper")
      this.result["number"] ? this.uncheckItem("number") : this.checkItem("number")
    }

    this.checkItem = function(id) {
      const item = $(`#${id}`);
      if (item.hasClass("complete")) return
      item.addClass("complete");
    }

    this.uncheckItem = function(id) {
      const item = $(`#${id}`);
      if (!item.hasClass("complete")) return
      item.removeClass("complete");
    }

  }
}