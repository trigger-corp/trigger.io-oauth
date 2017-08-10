#import <AppAuth/AppAuth.h>

#import "oauth_Delegate.h"
#import "oauth_API.h"

extern id<OIDAuthorizationFlowSession> currentAuthorizationFlow; // TODO not ideal

@implementation oauth_API


+ (void)authorize:(ForgeTask*)task config:(NSDictionary*)config {

    // TODO support implit flows? probably not because client secrets are a bad idea for devices…
    // https://stackoverflow.com/questions/16321455/
    // facebook, microsoft, github: https://github.com/iainmcgin/AppAuth-Demo
    // https://blog.gisspan.com/2017/02/Implementing-OAuth-on-mobile-Facebook-login-as-example.html

    // Option 1: discovery uri
    if ([config objectForKey:@"discovery_endpoint"]) {
        NSURL *discovery_endpoint = [NSURL URLWithString:[config objectForKey:@"discovery_endpoint"]];
        [OIDAuthorizationService discoverServiceConfigurationForDiscoveryURL:discovery_endpoint completion:^(OIDServiceConfiguration *_Nullable configuration, NSError *_Nullable error) {
            if (!configuration) {
                NSLog(@"Error retrieving discovery document: %@", [error localizedDescription]);
                [task error:[error localizedDescription]];
                return;
            }
            [oauth_API _authorize_with_configuration:task config:config configuration:configuration];
        }];
        return;
    }

    // Option 2: endpoint uris
    if ([config objectForKey:@"authorization_endpoint"] && [config objectForKey:@"token_endpoint"]) {
        NSURL *authorization_endpoint = [NSURL URLWithString:[config objectForKey:@"authorization_endpoint"]];
        NSURL *token_endpoint = [NSURL URLWithString:[config objectForKey:@"token_endpoint"]];
        OIDServiceConfiguration *configuration;
        if ([config objectForKey:@"registration_endpoint"]) {
            NSURL *registration_endpoint = [NSURL URLWithString:[config objectForKey:@"registration_endpoint"]];
            configuration = [[OIDServiceConfiguration alloc]initWithAuthorizationEndpoint:authorization_endpoint tokenEndpoint:token_endpoint registrationEndpoint:registration_endpoint];
        } else {
            configuration = [[OIDServiceConfiguration alloc]initWithAuthorizationEndpoint:authorization_endpoint tokenEndpoint:token_endpoint];
        }
        [oauth_API _authorize_with_configuration:task config:config configuration:configuration];
        return;
    }

    [task error:@"Options needs to contain either an authorization_endpoint & token_endpoint or a discovery_endpoint."
           type:@"EXPECTED_FAILURE" subtype:nil];
}


+ (void)_authorize_with_configuration:(ForgeTask*)task config:(NSDictionary*)config configuration:(OIDServiceConfiguration*)configuration {

    if (![config objectForKey:@"client_id"]) {
        [task error:@"Options needs to contain a client_id" type:@"EXPECTED_FAILURE" subtype:nil];
        return;
    }
    NSString *client_id = [config objectForKey:@"client_id"];

    if (![config objectForKey:@"redirect_uri"]) {
        [task error:@"Options needs to contain a redirect_uri" type:@"EXPECTED_FAILURE" subtype:nil];
        return;
    }
    NSURL *redirect_uri = [NSURL URLWithString:[config objectForKey:@"redirect_uri"]];

    NSString *authorization_scope = [config objectForKey:@"authorization_scope"]
                                  ? [config objectForKey:@"redirect_uri"]
                                  : @"email";

    oauth_Delegate *delegate = [oauth_Delegate delegateWithAuthorizationEndpoint:[configuration authorizationEndpoint]];
    [delegate authorize:configuration
              client_id:client_id redirect_uri:redirect_uri authorization_scope:authorization_scope
               callback:^(OIDAuthState *_Nullable authorizationState, NSError *_Nullable error) {
        if (!authorizationState) {
            [task error:[NSString stringWithFormat:@"Authorization error: %@", [error localizedDescription]] type:@"EXPECTED_FAILTURE" subtype:nil];
        } else {
            [task success:configuration.authorizationEndpoint.absoluteString];
        }
    }];
}


+ (void)actionWithToken:(ForgeTask*)task endpoint:(NSString*)endpoint {
    oauth_Delegate *delegate = [oauth_Delegate delegateWithAuthorizationEndpoint:[NSURL URLWithString:endpoint]];
    if (delegate.authorizationState == nil || !delegate.authorizationState.isAuthorized) {
        [task error:@"Endpoint is not authorized" type:@"EXPECTED_FAILTURE" subtype:nil];
        return;
    }

    [delegate.authorizationState performActionWithFreshTokens:^(NSString *_Nonnull accessToken,
                                                                NSString *_Nonnull idToken,
                                                                NSError *_Nullable error) {
        if (error) {
            NSLog(@"Error obtaining token: %@", [error localizedDescription]);
            [task error:[NSString stringWithFormat:@"Error obtaining token: %@", [error localizedDescription]]];
            return;
        }

        [task success:@{@"access": accessToken,
                        @"id": idToken }];
    }];
}


+ (void)signout:(ForgeTask*)task endpoint:(NSString*)endpoint {
    oauth_Delegate *delegate = [oauth_Delegate delegateWithAuthorizationEndpoint:[NSURL URLWithString:endpoint]];
    if (delegate.authorizationState != nil) {
        [delegate clearAuthorizationState];
    }
    [task success:nil];
}


/*+ (void)userProfile:(ForgeTask*)task authorization_endpoint:(NSString*)authorization_endpoint accessToken:(NSString*)accessToken idToken:(NSString*)idToken {

    oauth_Delegate *delegate = [oauth_Delegate delegateWithAuthorizationEndpoint:[NSURL URLWithString:authorization_endpoint]];
    if (delegate.authorizationState == nil || !delegate.authorizationState.isAuthorized) {
        [task error:@"Endpoint is not authorized" type:@"EXPECTED_FAILTURE" subtype:nil];
        return;
    }

    NSURL *userinfoEndpoint = delegate.authorizationState.lastAuthorizationResponse.request.configuration.discoveryDocument.userinfoEndpoint;
    if (!userinfoEndpoint) {
        NSLog(@"Userinfo endpoint not declared in discovery document");
        [task error:[NSString stringWithFormat:@"Userinfo endpoint not declared in discovery document"]];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:userinfoEndpoint];
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", accessToken];
    [request addValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:nil
                                                     delegateQueue:nil];

    // performs HTTP request
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
           if (error) {
               NSLog(@"HTTP request failed %@", error);
               [task error:[NSString stringWithFormat:@"HTTP request failed %@", error]];
               return;
           }
           if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
               NSLog(@"Non-HTTP response");
               [task error:@"Non-HTTP response"];
               return;
           }

           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
           id jsonDictionaryOrArray =
           [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

           if (httpResponse.statusCode != 200) {
               // server replied with an error
               NSString *responseText = [[NSString alloc] initWithData:data
                                                              encoding:NSUTF8StringEncoding];
               if (httpResponse.statusCode == 401) {
                   // "401 Unauthorized" generally indicates there is an issue with the authorization
                   // grant. Puts OIDAuthState into an error state.
                   NSError *oauthError =
                   [OIDErrorUtilities resourceServerAuthorizationErrorWithCode:0
                                                                 errorResponse:jsonDictionaryOrArray
                                                               underlyingError:error];
                   [delegate.authorizationState updateWithAuthorizationError:oauthError];
                   // log error
                   NSLog(@"Authorization Error (%@). Response: %@", oauthError, responseText);
                   [task error:[NSString stringWithFormat:@"Authorization Error (%@). Response: %@", oauthError, responseText]];
               } else {
                   NSLog(@"HTTP: %d. Response: %@", (int)httpResponse.statusCode, responseText);
                   [task error:[NSString stringWithFormat:@"HTTP: %d. Response: %@", (int)httpResponse.statusCode, responseText]];
               }
               return;
           }

           // success response
           NSLog(@"Success: %@", jsonDictionaryOrArray);
           [task success:jsonDictionaryOrArray];
       });
	}];

    [postDataTask resume];
}*/

@end
