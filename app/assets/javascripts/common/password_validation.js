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
    this.setTimer();
  }

  this.setTimer = function() {
    this.cancelTimer();
    this.timer = setTimeout(this.validatePassword, DebounceTimeout);
  }

  this.cancelTimer = function() {
    if (!this.timer) return;
    clearTimeout(this.timer);
    this.timer = null;
  }

  this.validatePassword = () => {
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
      if (status === "success") {
        this.updateResults(data["errors"]);
      } else {
        this.updateResults(DefaultResult);
      }
      this.timer = null;
      this.updateChecklist();
      this.updateSubmitStatus();
    });

    this.updateResults = function(response) {
      this.result["length"] = !response.includes("must be between 10 and 128 characters");
      this.result["lower"] = !response.includes("must contain at least one lower case letter");
      this.result["upper"] = !response.includes("must contain at least one upper case letter");
      this.result["number"] = !response.includes("must contain at least one number");
    }

    this.updateChecklist = function() {
      this.result["length"] ? this.checkItem("length") : this.uncheckItem("length")
      this.result["lower"] ? this.checkItem("lower") : this.uncheckItem("lower")
      this.result["upper"] ? this.checkItem("upper") : this.uncheckItem("upper")
      this.result["number"] ? this.checkItem("number") : this.uncheckItem("number")
    }

    this.checkItem = function(id) {
      const icon = $(`#${id}-icon`);
      icon.addClass("completed-icon");
      const text = $(`#${id}-text`);
      text.addClass("completed-text");
    }

    this.uncheckItem = function(id) {
      const icon = $(`#${id}-icon`);
      icon.removeClass("completed-icon");
      const text = $(`#${id}-text`);
      text.removeClass("completed-text");
    }

    this.updateSubmitStatus = function() {
      const button = $("#password-submit");
      const allPass = Object.values(this.result).every(item => item === true);
      if (allPass) {
        button.removeAttr("disabled");
      } else {
        button.attr("disabled", true);
      }
    }
  }
}