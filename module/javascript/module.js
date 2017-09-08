/* global forge */

forge.oauth = {
    authorize: function (config, success, error) {
        if (typeof config === "string") {
            var name = config;
            config = forge.config.modules.oauth.config.providers.find(function (provider) {
                return provider.name === name;
            });
            if (typeof config === "undefined") {
                error("Could not find a configuration for a provider called: " + name);
                return;
            }
        }
        forge.internal.call('oauth.authorize', {config: config}, success, error);
    },
    actionWithToken: function (endpoint, success, error) {
        forge.internal.call('oauth.actionWithToken', {endpoint: endpoint}, success, error);
    },
    signout: function (config, success, error) {
        if (typeof config === "string") {
            var name = config;
            config = forge.config.modules.oauth.config.providers.find(function (provider) {
                return provider.name === name;
            });
            if (typeof config === "undefined") {
                error("Could not find a configuration for a provider called: " + name);
                return;
            }
        }
        forge.internal.call('oauth.signout', {config:config}, success, error);
    }
};
