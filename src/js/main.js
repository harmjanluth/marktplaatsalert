var marktplaats_alert;

marktplaats_alert = {};

(function() {
  var addAlertForm, auth, fireAlert, getTodayFormatted, initialize, loggedIn, numberOfAlerts, showLogin, uid;
  uid = null;
  numberOfAlerts = null;
  addAlertForm = document.getElementById("add-alert-form");
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
      if (!preferences.timeout) {
        return;
      }
      $("#set-preferences [name=period]").val(preferences.period);
      return $("#set-preferences [name=times]").val(preferences.times);
    });
    return $("#set-preferences select").on("change", function() {
      var period, timeout, times;
      period = $("#set-preferences [name=period]").val();
      times = $("#set-preferences [name=times]").val();
      timeout = period / times;
      return fireAlert.child("users/" + uid + "/preferences").set({
        timeout: timeout,
        period: period,
        times: times
      });
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
