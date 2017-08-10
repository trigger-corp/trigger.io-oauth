/* global forge, pforge, asyncTest, askQuestion, ok, start, $ */
/* jslint node: true */

module("oauth");

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
    }).done(function (data) {
        forge.logging.log("Discovery endpoint says: " + JSON.stringify(data));
        askQuestion("Does this look like Google's endpoints: <pre>" + JSON.stringify(data, null, 2) + "</pre>", {
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
    pforge.oauth.authorize(config_google_discovery).then(function (endpoint) {
        return pforge.oauth.actionWithToken(endpoint);
    }).then(function (token) {
        $.ajax({
            url: "https://www.googleapis.com/oauth2/v3/userinfo", // TODO pull from a forge.oauth API
            headers: {
                "Authorization": "Bearer " + token.access
            }
        }).fail(function (e) {
            ok(false, "REST request failed: " + JSON.stringify(e));
            start();
        }).done(function (profile) {
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
        });
    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});


asyncTest("Attempt to get user profile information from Google 2", 1, function () {
    pforge.oauth.authorize(config_google_discovery).then(function (endpoint) {
        return pforge.oauth.actionWithToken(endpoint);

    }).then(function (token) {
        return $.ajax({
            url: "https://www.googleapis.com/oauth2/v3/userinfo", // TODO pull from a forge.oauth API
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
asyncTest("Sign out of Google", 1, function () {
    pforge.oauth.authorize(config_google_discovery).then(function (endpoint) {
        return pforge.oauth.signout(endpoint);
    }).then(function () {
        ok(true, "User claims success");
        start();
    }).catch(function (e) {
        ok(false, "API method returned failure: " + JSON.stringify(e));
        start();
    });
});
*/
