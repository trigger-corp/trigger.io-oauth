``oauth``: Native OAuth support for your app.
=============================================

The ``forge.oauth`` namespace allows your app to communicate securely with OAuth 2.0 and OpenID Connect providers.

The module is a wrapper around the [OpenID](https://github.com/openid) AppAuth
library and follows the best practices set out in the
[OAuth 2.0 for Native Apps Draft Proposal](https://tools.ietf.org/html/draft-ietf-oauth-native-apps-12)
including using SFSafariViewController on iOS and Custom Tabs on Android
for the auth request.


##Configuration

redirect_scheme
:   The redirect scheme used by AppAuth to return to your app after completion of the authorization flow.



### Examples


##API

!method:forge.oauth.authorize(provider, success, error)
!param: provider `string` a name referring to a oauth provider specified in the module's config
!param: success `function(endpoint)` callback to be invoked after successful authorization
!param: error   `function(error)` called when authorization has not succeeded for any reason
!platforms: iOS, Android
!description: Initiate an authorization flow for the user against the specified provider.


!method:forge.oauth.actionWithToken(endpoint, success, error)
!param: endpoint `string` a uri referring to an endpoint returned by forge.oauth.authorize
!param: success `function(token)` callback to be invoked when no errors occur
!param: error   `function(error)` called with details of any error which may occur
!platforms: iOS, Android
!description: Used to obtain a token that can be used to access the endpoints of the service that has been authorized.


!method:forge.oauth.signout(endpoint, success, error)
!param: endpoint `string` a uri referring to an endpoint returned by forge.oauth.authorize
!param: success `function()` callback to be invoked when the user has been logged out
!param: error   `function(error)` called with details of any error which may occur
!platforms: iOS, Android
!description: Logs the user out from a provider endpoint returned by forge.oauth.authorize.



## Examples


### Google

    var state = {};
    pforge.oauth.authorize(config_google_discovery).then(function (endpoint) {
        return pforge.oauth.actionWithToken(endpoint);

    }).then(function (token) {
        state.token = token;
        return $.ajax({
            url: config_google_discovery.discovery_endpoint,
            headers: {
                "Authorization": "Bearer " + state.token.access
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
        // ... do something with user profile

    }).catch(function (e) {
        // ... handle error
    });
