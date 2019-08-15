//
//  oauth_Delegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/08/02.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AppAuth/AppAuth.h>


@interface oauth_Delegate : UIResponder <UIApplicationDelegate> {
}

@property(nonatomic, strong, nullable) NSString *persistKey;
@property(nonatomic, strong, nullable) OIDAuthState *authorizationState;
@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;
@property(nonatomic, strong, nullable) OIDAuthorizationRequest *request;

+ (oauth_Delegate*_Nullable) delegateWithAuthorizationEndpoint:(NSURL*_Nonnull)authorizationEndpoint;

- (void)restoreAuthorizationState;
- (void)updateAuthorizationState:(OIDAuthState*_Nonnull)authorizationState;
- (void)clearAuthorizationState;

- (void)authorizeWithConfiguration:(OIDServiceConfiguration*_Nonnull)configuration
        client_id:(NSString*_Nonnull)client_id client_secret:(NSString*_Nullable)client_secret
     redirect_uri:(NSURL*_Nonnull)redirect_uri authorization_scope:(NSString*_Nonnull)authorization_scope
         callback:(OIDAuthStateAuthorizationCallback _Nonnull)callback;

@end



