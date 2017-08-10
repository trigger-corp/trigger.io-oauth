//
//  oauth_Delegate.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/08/02.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import "oauth_Delegate.h"

id<OIDAuthorizationFlowSession> currentAuthorizationFlow;


@implementation oauth_Delegate

+ (oauth_Delegate*) delegateWithAuthorizationEndpoint:(NSURL*)authorizationEndpoint {
    oauth_Delegate *delegate = [oauth_Delegate alloc];
    if (![delegate init]) {
        return nil;
    }
    delegate.persistKey = [NSString stringWithFormat:@"oauth/%@", authorizationEndpoint.absoluteString];
    delegate.authorizationState = nil;
    [delegate restoreAuthorizationState];
    return delegate;
}


- (void)restoreAuthorizationState {
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    NSData *data = [prefs objectForKey:_persistKey];
    if (data == nil) {
        return;
    }
    _authorizationState = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (_authorizationState == nil) {
        return;
    }
    [ForgeLog d:[NSString stringWithFormat:@"Found authorization state for endpoint: %@ => %d", _persistKey, _authorizationState.isAuthorized]];
}


- (void)updateAuthorizationState:(OIDAuthState*)authorizationState {
    _authorizationState = authorizationState;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSKeyedArchiver archivedDataWithRootObject:_authorizationState] forKey:_persistKey];
    [prefs synchronize];
}


- (void)clearAuthorizationState {
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:_persistKey];
}


- (void)authorize:(OIDServiceConfiguration*_Nonnull)configuration
        client_id:(NSString*_Nonnull)client_id redirect_uri:(NSURL*)redirect_uri authorization_scope:(NSString*)authorization_scope
         callback:(OIDAuthStateAuthorizationCallback _Nonnull )callback
{
    if (_authorizationState != nil && _authorizationState.isAuthorized) {
        [ForgeLog d:[NSString stringWithFormat:@"Have an authorization state and it is: %@", _authorizationState]];
        callback(_authorizationState, NULL);
        return;
    }

    OIDAuthorizationRequest *request = [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                                                     clientId:client_id
                                                                                       scopes:[authorization_scope componentsSeparatedByString:@" "]
                                                                                  redirectURL:redirect_uri
                                                                                 responseType:OIDResponseTypeCode
                                                                         additionalParameters:nil];
    currentAuthorizationFlow = [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                                                       presentingViewController:[[ForgeApp sharedApp] viewController]
    callback:^(OIDAuthState *_Nullable authorizationState, NSError *_Nullable error) {
        [self updateAuthorizationState:authorizationState];
        callback(authorizationState, error);
    }];
}


@end


