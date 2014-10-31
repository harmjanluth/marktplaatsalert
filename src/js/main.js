var marktplaats_alert;

marktplaats_alert = {};

(function() {
  var addAlertForm, auth, fireAlert, getTodayFormatted, initialize, loggedIn, numberOfAlerts, reExPostalCode, showLogin, uid, updateUserPreferences;
  uid = null;
  numberOfAlerts = null;
  addAlertForm = document.getElementById("add-alert-form");
  reExPostalCode = /^[1-9][0-9]{3}[\s]?[A-Za-z]{2}$/i;
  fireAlert = new Firebase("https://marktplaats-alert.firebaseIO.com");
  auth = new FirebaseSimpleLogin(fireAlert, function(error, user) {
    if (user) {
      fireAlert.child("users/" + user.uid + "/profile").transaction(function(data) {
        uid = user.uid;
        if (user.displayName) {
          $(".welcome span").html(user.displayName);
        }
        return user;
      });
      loggedIn();
    } else {
      showLogin();
    }
  });
  loggedIn = function() {
    initialize();
    document.body.className = "logged-in";
    return $(".logout").on("click", function() {
      auth.logout();
      return document.body.className = "";
    });
  };
  showLogin = function() {
    document.body.className = "";
    document.querySelector(".login-facebook").onclick = function() {
      return auth.login("facebook", {
        rememberMe: true
      });
    };
    document.querySelector(".login-twitter").onclick = function() {
      return auth.login("twitter", {
        rememberMe: true
      });
    };
    return document.querySelector(".login-google").onclick = function() {
      return auth.login("google", {
        rememberMe: true
      });
    };
  };
  $("#add-alert-form").on("submit onsubmit", function() {
    var query;
    if (numberOfAlerts > 9) {
      window.alert("Maximum aantal zoekopdrachten (voor nu) is 10, verwijder eerst andere zoekopdrachten om een nieuwe toe te voegen.");
      return;
    }
    query = document.getElementById("alert-query-input").value;
    fireAlert.child("users/" + uid + "/alerts").push({
      query: query,
      created: Date.now()
    });
    document.getElementById("alert-query-input").value = "";
    return false;
  });
  $("body").on("click", "li", function() {
    var id;
    id = $(this).attr("data-id");
    if (id) {
      return fireAlert.child("users/" + uid + "/alerts/" + id).remove();
    }
  });
  initialize = function() {
    fireAlert.child("users/" + uid + "/alerts").on("value", function(snapshot) {
      var html, myAlerts, rows, template;
      if (!snapshot) {
        return;
      }
      myAlerts = snapshot.val();
      template = _.template(document.getElementById("tpl-alerts").innerHTML);
      numberOfAlerts = _.size(myAlerts);
      rows = {
        alerts: myAlerts
      };
      html = template(rows);
      return document.querySelector(".alerts-list").innerHTML = html;
    });
    fireAlert.child("users/" + uid + "/preferences").once("value", function(snapshot) {
      var preferences;
      preferences = snapshot.val();
      if (!preferences) {
        return;
      }
      console.log(preferences);
      $("#set-preferences [name=period]").val(preferences.period);
      $("#set-preferences [name=times]").val(preferences.times);
      $("#set-preferences [name=postalcode]").val(preferences.postalcode);
      $("#set-preferences [name=distance]").val(preferences.distance / 1000);
      $("#set-preferences [name=range]").prop("checked", preferences.range);
      if (preferences.range) {
        return $(".range-filter").addClass("active");
      }
    });
    $("#set-preferences select").on("change", function() {
      return updateUserPreferences();
    });
    $(".range-filter [type=text]").on("keyup", function() {
      var distance, postalcode;
      distance = $("[name=distance]").val();
      postalcode = $("[name=postalcode]").val();
      if (postalcode && reExPostalCode.test(postalcode)) {
        if (distance) {
          $(".range-filter [name=range]").prop("checked", true);
          $(".range-filter").addClass("active");
        }
        updateUserPreferences();
      }
      if ($(this).hasClass("input-postalcode")) {
        if (reExPostalCode.test(postalcode)) {
          return $("[name=postalcode]").removeClass("invalid");
        }
      }
    });
    $(".range-filter [type=text]").on("blur", function() {
      var postalcode, value;
      value = $(this).val();
      postalcode = $("[name=postalcode]").val();
      if ($(this).hasClass("input-postalcode")) {
        if (!reExPostalCode.test(postalcode) && postalcode.length) {
          $("[name=postalcode]").addClass("invalid");
          $(".range-filter [name=range]").prop("checked", false);
        }
      }
      if (!value.length) {
        $(".range-filter [name=range]").prop("checked", false);
        $(".range-filter").removeClass("active");
      }
      return updateUserPreferences();
    });
    return $(".range-filter [name=range]").on("click", function() {
      var postalcode;
      postalcode = $("[name=postalcode]").val();
      if ($(this).prop("checked")) {
        $(".range-filter").addClass("active");
      } else {
        $(".range-filter").removeClass("active");
      }
      if (postalcode.length) {
        if (!reExPostalCode.test(postalcode)) {
          $("[name=postalcode]").addClass("invalid");
        }
      }
      return updateUserPreferences();
    });
  };
  updateUserPreferences = function() {
    var distance, period, postalcode, range, timeout, times;
    period = $("#set-preferences [name=period]").val();
    times = $("#set-preferences [name=times]").val();
    range = $(".range-filter [name=range]").prop("checked");
    distance = $("[name=distance]").val();
    postalcode = $("[name=postalcode]").val();
    timeout = period / times;
    return fireAlert.child("users/" + uid + "/preferences").set({
      timeout: timeout,
      period: period,
      times: times,
      distance: distance * 1000,
      postalcode: postalcode,
      range: range
    });
  };
  getTodayFormatted = function() {
    var date;
    date = new Date();
    return (date.getMonth() + 1) + "-" + date.getDate() + "-" + date.getFullYear().toString().substr(2, 2);
  };
  return window.addEventListener("load", (function() {
    FastClick.attach(document.body);
  }), false);
})();
