/* global forge, pforge, asyncTest, askQuestion, ok, start, $ */
/* jslint node: true */

module("oauth");

var config_facebook = {
    "client_id": "617039718370339",
    "client_secret": "8344897fc28e067086bae1648596928c",
    "redirect_uri": "https://appauth.demo-app.io/oauth2redirect",
    //"redirect_uri": "https://docker.trigger.io/oauth2redirect",
    "authorization_scope": "public_profile",
    "authorization_endpoint": "https://www.facebook.com/dialog/oauth",
    "token_endpoint": "https://graph.facebook.com/v2.5/oauth/access_token"
};


asyncTest("Attempt to make a oauth login to Facebook", 1, function () {
    pforge.oauth.authorize(config_facebook).then(function (endpoint) {
        askQuestion("Is this Facebook's authorization endpoint: " + JSON.stringify(endpoint), {
            Yes: function () {
                ok(true, "User claims success");
                start();
            },
            No: function () {
                ok(false, "User claims failure");
                start();
            }
        });

    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});


asyncTest("Attempt to get user profile information from Facebook", 1, function () {
    pforge.oauth.authorize(config_facebook).then(function (endpoint) {
        return pforge.oauth.actionWithToken(endpoint);
    }).then(function (token) {
        return $.ajax({
            url: "https://graph.facebook.com/v2.5/me",
            headers: {
                "Authorization": "Bearer " + token.access
            }
        });

    }).then(function (profile) {
        askQuestion("Is this your user profile: <pre>" + JSON.stringify(profile, null, 2) + "</pre>", {
            Yes: function () {
                ok(true, "User claims success");
                start();
            },
            No: function () {
                ok(false, "User claims failure");
                start();
            }
        });

    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});


/*
var config_google_discovery = {
    discovery_endpoint: "https://accounts.google.com/.well-known/openid-configuration",
    client_id: "627734613405-irkg4q6dbq01h0so0ltb17f9kgc4ubfn.apps.googleusercontent.com",
    redirect_uri: "com.googleusercontent.apps.627734613405-irkg4q6dbq01h0so0ltb17f9kgc4ubfn:/oauth2redirect",
    scope: "openid email profile"
};

var config_google_manual = {
    authorization_endpoint: "https://accounts.google.com/o/oauth2/v2/auth",
    token_endpoint: "https://www.googleapis.com/oauth2/v4/token",
    client_id: "627734613405-irkg4q6dbq01h0so0ltb17f9kgc4ubfn.apps.googleusercontent.com",
    redirect_uri: "com.googleusercontent.apps.627734613405-irkg4q6dbq01h0so0ltb17f9kgc4ubfn:/oauth2redirect",
    scope: "openid email profile"
};


asyncTest("Attempt to sign out of Google", 1, function () {
    pforge.oauth.signout(config_google_manual.authorization_endpoint).then(function () {
        ok(true, "Function call succeeded");
        start();
    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});


asyncTest("Query discovery endpoint", function () {
    $.ajax({
        url: config_google_discovery.discovery_endpoint,
    }).fail(function (e) {
        ok(false, "REST request failed: " + JSON.stringify(e));
        start();
    }).done(function (response) {
        forge.logging.log("Discovery endpoint says: " + JSON.stringify(response));
        askQuestion("Does this look like Google's endpoints: <pre>" + JSON.stringify(response, null, 2) + "</pre>", {
            Yes: function () {
                ok(true, "User claims success");
                start();
            },
            No: function () {
                ok(false, "User claims failure");
                start();
            }
        });
    });
});


asyncTest("Attempt to make a oauth login to Google", 1, function () {
    pforge.oauth.authorize(config_google_discovery).then(function (endpoint) {
        askQuestion("Is this Google's authorization endpoint: " + JSON.stringify(endpoint), {
            Yes: function () {
                ok(true, "User claims success");
                start();
            },
            No: function () {
                ok(false, "User claims failure");
                start();
            }
        });

    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});


asyncTest("Attempt to get user profile information from Google", 1, function () {
    var state = {};
    pforge.oauth.authorize(config_google_discovery).then(function (endpoint) {
        return pforge.oauth.actionWithToken(endpoint);

    }).then(function (token) {
        state.token = token;
        return $.ajax({
            url: config_google_discovery.discovery_endpoint,
            headers: {
                "Authorization": "Bearer " + token.access
            }
        });

    }).then(function (response) {
        return $.ajax({
            url: response.userinfo_endpoint,
            headers: {
                "Authorization": "Bearer " + state.token.access
            }
        });

    }).then(function (profile) {
        askQuestion("Is this your user profile: <pre>" + JSON.stringify(profile, null, 2) + "</pre>", {
            Yes: function () {
                ok(true, "User claims success");
                start();
            },
            No: function () {
                ok(false, "User claims failure");
                start();
            }
        });

    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});
*/
