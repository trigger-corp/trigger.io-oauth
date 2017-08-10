//
//  oauth_API.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/08/02.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import <AppAuth/AppAuth.h>

#import "oauth_Delegate.h"
#import "oauth_API.h"

extern id<OIDAuthorizationFlowSession> currentAuthorizationFlow;

@implementation oauth_API

+ (void)authorize:(ForgeTask*)task config:(NSDictionary*)config {
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

    NSString *client_secret = [config objectForKey:@"client_secret"]
                            ? [config objectForKey:@"client_secret"]
                            : NULL;

    if (![config objectForKey:@"redirect_uri"]) {
        [task error:@"Options needs to contain a redirect_uri" type:@"EXPECTED_FAILURE" subtype:nil];
        return;
    }
    NSURL *redirect_uri = [NSURL URLWithString:[config objectForKey:@"redirect_uri"]];

    NSString *authorization_scope = [config objectForKey:@"authorization_scope"]
                                  ? [config objectForKey:@"authorization_scope"]
                                  : @"email";

    oauth_Delegate *delegate = [oauth_Delegate delegateWithAuthorizationEndpoint:[configuration authorizationEndpoint]];
    [delegate authorizeWithConfiguration:configuration
              client_id:client_id client_secret:client_secret
           redirect_uri:redirect_uri authorization_scope:authorization_scope
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
            [task error:[NSString stringWithFormat:@"Error obtaining token: %@", [error localizedDescription]] type:@"EXPECTED_FAILTURE" subtype:nil];
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


@end
