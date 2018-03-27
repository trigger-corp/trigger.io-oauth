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

### Providers

The `providers` section consists of one or more provider definitions consisting of the following keys:

name
:   A descriptive name to use when referring to the provider through forge.oauth API calls

client_id
:   A client id assigned by the OAauth provider.

client_secret
:   A client secret assigned by the OAuth provider. (Optional)

redirect_uri
:   Redirect URI invoked by the OAuth provider to return the OAuth response.

authorization_scope
:   OpenID scope string for authorization request. (Optional).

discovery_endpoint
:   Discovery endpoint for OAuth and OpenID services offered by  the provider.

authorization_endpoint
:   Authorization endpoint for OAuth provider. (Not required if `discovery_endpoint` is provided)

token_endpoint
:   Token endpoint for OAuth provider. (Not required if `discovery_endpoint` is provided)

registration_endpoint
:   Registration endpoint for OAuth provider. (Not required if `discovery_endpoint` is provided)



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

!method:forge.oauth.discover(endpoint, success, error)
!param: endpoint `string` a name referring to a oauth provider specified in the module's config
!param: success `function(configuration)` callback to be invoked with discovered configuration
!param: error   `function(error)` called with details of any error which may occur
!platforms: iOS, Android
!description: Queries the OAuth service discovery endpoint. (If configured)


---

## Example: Google

#### Provider Configuration

    "oauth2": {
        "version": "1.x",
        "config": {
            "redirect_scheme": "com.googleusercontent.apps.xxx",
            "providers": [
                {
                    "name": "google",
                    "client_id": "xxx.apps.googleusercontent.com",
                    "discovery_endpoint": "https://accounts.google.com/.well-known/openid-configuration",
                    "redirect_uri": "com.googleusercontent.apps.xxx:/oauth2redirect",
                    "authorization_scope": "openid email profile"
                }
            ]
        }
    }

#### Making a Request

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

    }).then(function (userinfo) {
        // do something with the requested information

    }).catch(function (error) {
        // handle any errors
    });


---

## Example: Facebook

See our [Facebook OAuth Tutorial](tutorial-facebook.html) for a more detailed example.


#### Provider Configuration

    "oauth2": {
        "version": "1.x",
        "config": {
            "redirect_scheme": "io.trigger.example.oauth2",
            "providers": [
                {
                    "name": "facebook",
                    "client_id": "xxx",
                    "client_secret": "xxx",
                    "authorization_endpoint": "https://www.facebook.com/dialog/oauth",
                    "token_endpoint": "https://graph.facebook.com/v2.5/oauth/access_token",
                    "redirect_uri": "https://trigger.io/example/oauth2redirect",
                    "authorization_scope": "public_profile"
                }
            ]
        }
    }

#### Making a Request


    forge.oauth.authorize("facebook").then(function (endpoint) { // authorize this client
        return forge.oauth.actionWithToken(endpoint);                 // so we can request a token

    }).then(function (token) {
        return $.ajax({                                               // to make a request
            url: "https://graph.facebook.com/v2.5/me",                // to a Facebook REST API
            headers: {
                "Authorization": "Bearer " + token.access             // as an authorized client
            }
        });

    }).then(function (me) {
        // do something with the requested information

    }).catch(function (error) {
        // handle any errors
    });


#### Redirect Page

    <!DOCTYPE html>
    <html>
        <body>
            <a id="proceed" href="/">Click to return to app</a>
            <script>
                var newOrigin = "io.trigger.example.oauth2:/";
                var uriSuffix = window.location.href.substring(window.location.origin.length + 1);
                document.getElementById("proceed").href = newOrigin + uriSuffix;
            </script>
        </body>
    </html>
