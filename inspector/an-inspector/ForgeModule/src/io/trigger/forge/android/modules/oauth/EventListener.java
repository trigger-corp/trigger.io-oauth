package io.trigger.forge.android.modules.oauth;

import android.content.Intent;

import net.openid.appauth.AuthorizationException;
import net.openid.appauth.AuthorizationResponse;
import net.openid.appauth.AuthorizationService;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeEventListener;
import io.trigger.forge.android.core.ForgeLog;

public class EventListener extends ForgeEventListener {
    @Override
    public void onStart() {
        ForgeLog.d("oauth::onStart");
        Delegate.authService = new AuthorizationService(ForgeApp.getActivity().getApplicationContext());
    }

    @Override
    public void onStop() {
        ForgeLog.d("oauth::onStop");
        Delegate.authService.dispose();
    }


    @Override
    public void onNewIntent(Intent intent) {
        if (intent == null) {
            return;
        }

        final AuthorizationResponse authorizationResponse = AuthorizationResponse.fromIntent(intent);
        AuthorizationException authorizationException = AuthorizationException.fromIntent(intent);
        if (authorizationResponse == null
                || !authorizationResponse.request.additionalParameters.containsKey("io.trigger.forge.modules.oauth")) {
            ForgeLog.e("oauth.EventListener::onNewIntent failed to respond to an unknown intent: " + intent.toString());
            return;
        }

        String callid = authorizationResponse.request.additionalParameters.get("io.trigger.forge.modules.oauth");
        final Delegate delegate = Delegate.TaskMap.remove(callid);
        if (delegate == null) {
            ForgeLog.e("Could not determine delegate for authorization request with callid: " + callid);
            return;
        }

        if (delegate.intentCallback == null) {
            ForgeLog.e("No intent callback for delegate: " + delegate.authorizationEndpoint.toString());
            return;
        }
        delegate.intentCallback.run(authorizationResponse, authorizationException);
    }
}
