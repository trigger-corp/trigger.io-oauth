/* global forge, asyncTest, askQuestion, ok, start, $ */
/* jslint node: true */

module("oauth");
forge.flags.promises(true);

var config_google = {
    "client_id": "627734613405-irkg4q6dbq01h0so0ltb17f9kgc4ubfn.apps.googleusercontent.com",
    "discovery_endpoint": "https://accounts.google.com/.well-known/openid-configuration",
    "redirect_uri": "com.googleusercontent.apps.627734613405-irkg4q6dbq01h0so0ltb17f9kgc4ubfn:/oauth2redirect",
    "authorization_scope": "openid email profile"
};


var config_facebook = {
    "client_id": "617039718370339",
    "client_secret": "8344897fc28e067086bae1648596928c",
    "authorization_endpoint": "https://www.facebook.com/dialog/oauth",
    "token_endpoint": "https://graph.facebook.com/v2.5/oauth/access_token",
    "redirect_uri": "https://docker.trigger.io/oauth2redirect",
    "authorization_scope": "public_profile"
};


asyncTest("Attempt to sign out of Google", 1, function () {
    forge.oauth.signout("google").then(function () {
        ok(true, "Function call succeeded");
        start();

    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});


asyncTest("Query discovery endpoint", function () {
    forge.oauth.discover("google").then(function (configuration) {
        forge.logging.log("Discovery endpoint says: " + JSON.stringify(configuration));
        askQuestion("Does this look like Google's endpoints: <pre>" + JSON.stringify(configuration, null, 2) + "</pre>", {
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
        ok(false, "Failure: " + JSON.stringify(e));
        start();
    });
});


asyncTest("Attempt to make a oauth login to Google", 1, function () {
    forge.oauth.authorize(config_google).then(function (endpoint) {
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
    forge.oauth.discover("google").then(function (configuration) { // discover google endpoints
        state.configuration = configuration;                       // ... and save them for later
        return forge.oauth.authorize("google");                    // then authorize this client

    }).then(function (endpoint) {
        return forge.oauth.actionWithToken(endpoint);              // so we can request a token

    }).then(function (token) {
        return $.ajax({                                            // to make a request
            url: state.configuration.userinfo_endpoint,            // ... to one of the endpoints we saved
            headers: {
                "Authorization": "Bearer " + token.access          // as an authorized client
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


asyncTest("Attempt to sign out of Facebook", 1, function () {
    forge.oauth.signout("facebook").then(function () {
        ok(true, "Function call succeeded");
        start();

    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});


asyncTest("Attempt to make a oauth login to Facebook", 1, function () {
    forge.oauth.authorize("facebook").then(function (endpoint) {
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
    forge.oauth.authorize(config_facebook).then(function (endpoint) {
        return forge.oauth.actionWithToken(endpoint);
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
