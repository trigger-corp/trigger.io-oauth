/* global forge, pforge */

forge.oauth = {
    authorize: function (config, success, error) {
        if (typeof config === "function") {
            error = success;
            success = config;
            config = {};
        }
        forge.internal.call('oauth.authorize', {config: config}, success, error);
    },
    actionWithToken: function (endpoint, success, error) {
        forge.internal.call('oauth.actionWithToken', {endpoint: endpoint}, success, error);
    },
    signout: function (endpoint, success, error) {
        forge.internal.call('oauth.signout', {endpoint:endpoint}, success, error);
    }
};


/* - create a version of the API that supports promises ----------------- */

pforge.oauth = pforge.internal.promisify_module(forge, "oauth");
