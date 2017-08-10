package io.trigger.forge.android.modules.oauth;

import android.net.Uri;
import android.support.annotation.Nullable;

import com.google.gson.JsonObject;

import net.openid.appauth.AuthState;
import net.openid.appauth.AuthorizationException;
import net.openid.appauth.AuthorizationServiceConfiguration;
import net.openid.appauth.AuthorizationServiceConfiguration.RetrieveConfigurationCallback;
import net.openid.appauth.AuthorizationServiceDiscovery;

import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeParam;
import io.trigger.forge.android.core.ForgeTask;

public class API {

    public static void authorize(final ForgeTask task, @ForgeParam("config") final JsonObject config) {

        // Option 1: discovery uri
        if (config.has("discovery_endpoint")) {
            Uri discovery_endpoint = Uri.parse(config.get("discovery_endpoint").getAsString());
            RetrieveConfigurationCallback callback = new RetrieveConfigurationCallback() {
                public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration configuration,
                                                          @Nullable AuthorizationException authorizationException) {
                    if (authorizationException != null) {
                        ForgeLog.e("Failed to fetch oauth configuration: " + authorizationException.getLocalizedMessage());
                        task.error(authorizationException.getLocalizedMessage(), "UNEXPECTED_FAILURE", null);
                        return;
                    }
                    API._authorize_configuration(task, config, configuration);
                }
            };
            AuthorizationServiceConfiguration.fetchFromUrl(discovery_endpoint, callback);
            return;
        }

        // Option 2: endpoint uris
        if (config.has("authorization_endpoint") && config.has("token_endpoint")) {
            Uri authorization_endpoint = Uri.parse(config.get("authorization_endpoint").getAsString());
            Uri token_endpoint = Uri.parse(config.get("token_endpoint").getAsString());
            Uri registration_endpoint = config.has("registration_endpoint")
                    ? Uri.parse(config.get("registration_endpoint").getAsString())
                    : Uri.parse("https://trigger.io");
            AuthorizationServiceConfiguration configuration = new AuthorizationServiceConfiguration(authorization_endpoint, token_endpoint, registration_endpoint);
            API._authorize_configuration(task, config, configuration);
            return;
        }

        task.error("Options needs to contain either an authorization_endpoint & token_endpoint or a discovery_endpoint.", "EXPECTED_FAILURE", null);
    }


    private static void _authorize_configuration(final ForgeTask task, final JsonObject options, final AuthorizationServiceConfiguration configuration) {

        if (!options.has("client_id")) {
            task.error("Options needs to contain a client_id", "EXPECTED_FAILURE", null);
            return;
        }
        final String client_id = options.get("client_id").getAsString();

        if (!options.has("redirect_uri")) {
            task.error("Options needs to contain a redirect_uri", "EXPECTED_FAILURE", null);
            return;
        }
        final String redirect_uri = options.get("redirect_uri").getAsString();

        final String authorization_scope = options.has("authorization_scope")
                ? options.get("authorization_scope").getAsString()
                : "email";

        Delegate delegate = Delegate.delegateWithAuthorizationEndpoint(configuration.authorizationEndpoint);
        delegate.authorize(task.callid, configuration, client_id, redirect_uri, authorization_scope, new Delegate.APICallback() {
            @Override
            public void run(AuthState authorizationState, AuthorizationException ex) {
                if (ex != null) {
                    ForgeLog.e("Failed to perform authorization request: " + ex.getLocalizedMessage());
                    task.error(ex.getLocalizedMessage(), "UNEXPECTED_FAILURE", null);
                    return;
                }
                // TODO add and/or cache other endpoints?
                AuthorizationServiceDiscovery discovery = authorizationState.getAuthorizationServiceConfiguration().discoveryDoc;
                Uri userInfoEndpoint = discovery.getUserinfoEndpoint();
                ForgeLog.d("USERINFO ENDPOINT: " + userInfoEndpoint.toString());
                task.success(configuration.authorizationEndpoint.toString());
            }
        });
    }

    public static void actionWithToken(final ForgeTask task, @ForgeParam("endpoint") final String endpoint) {
        Delegate delegate = Delegate.delegateWithAuthorizationEndpoint(Uri.parse(endpoint));
        if (delegate == null || !delegate.authorizationState.isAuthorized()) {
            task.error("Endpoint is not authorized", "EXPECTED_FAILURE", null);
            return;
        }
        delegate.authorizationState.performActionWithFreshTokens(Delegate.authService, new AuthState.AuthStateAction() {
            @Override
            public void execute(@Nullable String accessToken, @Nullable String idToken, @Nullable AuthorizationException ex) {
                if (ex != null) {
                    task.error(ex.getLocalizedMessage(), "UNEXPECTED_FAILURE", null);
                    return;
                }
                JsonObject ret = new JsonObject();
                ret.addProperty("access", accessToken);
                ret.addProperty("id", idToken);
                task.success(ret);
            }
        });
    }


    public static void signout(final ForgeTask task, @ForgeParam("endpoint") final String endpoint) {
        Delegate delegate = Delegate.delegateWithAuthorizationEndpoint(Uri.parse(endpoint));
        if (delegate != null) {
            delegate.clearAuthorizationState();
        }
        task.success();
    }

}


