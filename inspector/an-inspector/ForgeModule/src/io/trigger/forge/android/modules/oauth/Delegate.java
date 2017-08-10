package io.trigger.forge.android.modules.oauth;

import android.app.PendingIntent;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;

import net.openid.appauth.AuthState;
import net.openid.appauth.AuthorizationException;
import net.openid.appauth.AuthorizationRequest;
import net.openid.appauth.AuthorizationResponse;
import net.openid.appauth.AuthorizationService;
import net.openid.appauth.AuthorizationServiceConfiguration;
import net.openid.appauth.ResponseTypeValues;
import net.openid.appauth.TokenResponse;

import org.json.JSONException;

import java.util.HashMap;

import io.trigger.forge.android.core.ForgeActivity;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeLog;

import static android.content.Context.MODE_PRIVATE;




public class Delegate {

    public static HashMap<String, Delegate> TaskMap = new HashMap<>();
    public static AuthorizationService authService; // not sure if can be static


    public AuthState authorizationState;
    public Uri authorizationEndpoint;


    public interface IntentCallback {
        public void run(final AuthorizationResponse response, final AuthorizationException ex);
    }
    public IntentCallback intentCallback;

    public interface APICallback {
        public void run(final AuthState response, final AuthorizationException ex);
    }


    public static Delegate delegateWithAuthorizationEndpoint(Uri authorizationEndpoint) {
        Delegate delegate = new Delegate();
        delegate.intentCallback = null;
        delegate.authorizationState = new AuthState();
        delegate.authorizationEndpoint = authorizationEndpoint;
        delegate.restoreAuthorizationState();
        return delegate;
    }


    public void restoreAuthorizationState() {
        SharedPreferences prefs = ForgeApp.getActivity().getSharedPreferences("oauth", MODE_PRIVATE);
        ForgeLog.d("Trying to restore auth state for: " + this.authorizationEndpoint.toString());
        String json = prefs.getString(this.authorizationEndpoint.toString(), null);
        if (json == null) {
            ForgeLog.e("No cached authorization state for endpoint");
            return;
        }
        AuthState state = null;
        try {
            state = AuthState.jsonDeserialize(json);
        } catch (JSONException e) {}
        if (state == null) {
            ForgeLog.e("Failed to deserialize authorization state for endpoint");
            return;
        }
        ForgeLog.d("Found authorization state for endpoint: " + this.authorizationEndpoint + " => " + state.isAuthorized());
        this.authorizationState = state;
    }

    private void persistAuthorizationState() {
        ForgeLog.d("Persisting auth state for: " + authorizationEndpoint.toString());
        try {
            SharedPreferences.Editor editor = ForgeApp.getActivity().getSharedPreferences("oauth", MODE_PRIVATE).edit();
            editor.putString(authorizationEndpoint.toString(), authorizationState.jsonSerialize().toString());
            editor.commit();
            ForgeLog.d("Wrote: " + authorizationState.jsonSerialize().toString());
        } catch (Exception e) {
            ForgeLog.e("Error persisting authorization state cache: " + e.getLocalizedMessage());
        }
    }


    public void clearAuthorizationState() {
        SharedPreferences.Editor editor = ForgeApp.getActivity().getSharedPreferences("oauth", MODE_PRIVATE).edit();
        editor.remove(authorizationEndpoint.toString());
        editor.commit();
    }


    public void authorize(final String callid, final AuthorizationServiceConfiguration configuration,
                          final String client_id, final String redirect_uri, final String authorization_scope,
                          final APICallback callback) {

        if (this.authorizationState.isAuthorized()) {
        ForgeLog.d("Have an authorization state and it is:" + this.authorizationState);
            callback.run(this.authorizationState, null);
            return;
        }

        Delegate.TaskMap.put(callid, this);

        AuthorizationRequest.Builder authRequestBuilder =
                new AuthorizationRequest.Builder(configuration,     // the authorization service configuration
                        client_id,                // the client ID, typically pre-registered and static
                        ResponseTypeValues.CODE,  // the response_type value: we want a code
                        Uri.parse(redirect_uri)); // the redirect URI to which the auth response is sent

        HashMap<String, String> taskInfo = new HashMap<String, String>();
        taskInfo.put("io.trigger.forge.modules.oauth", callid);
        AuthorizationRequest authRequest = authRequestBuilder
                .setScope(authorization_scope)
                //.setLoginHint("bob@gmail.com") // TODO make it an option
                .setAdditionalParameters(taskInfo)
                .build();

        final Delegate self = this;

        // Step 3: Receive TokenResponse
        final AuthorizationService.TokenResponseCallback tokenResponseCallback = new AuthorizationService.TokenResponseCallback() {
            @Override
            public void onTokenRequestCompleted(TokenResponse response, AuthorizationException exception) {
                self.authorizationState.update(response, exception);
                self.persistAuthorizationState();
                callback.run(self.authorizationState, exception);
            }
        };

        // Step 2: Receive AuthorizationResponse
        this.intentCallback = new IntentCallback() {
            @Override
            public void run(AuthorizationResponse response, AuthorizationException exception) {
                self.authorizationState.update(response, exception);
                self.persistAuthorizationState();
                Delegate.authService.performTokenRequest(response.createTokenExchangeRequest(), tokenResponseCallback);
            }
        };

        // Step 1: Kick off authorization flow
        Intent intent = new Intent(ForgeApp.getActivity().getApplicationContext(), ForgeActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(ForgeApp.getActivity(), 0, intent, 0);
        Delegate.authService.performAuthorizationRequest(authRequest, pendingIntent);
    }
}
