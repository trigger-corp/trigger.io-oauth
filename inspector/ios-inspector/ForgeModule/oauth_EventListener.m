//
//  oauth_EventListener.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/08/02.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import "oauth_Delegate.h"
#import "oauth_EventListener.h"

extern id<OIDAuthorizationFlowSession> currentAuthorizationFlow; // TODO not ideal

@implementation oauth_EventListener

+ (NSNumber *)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
        return @YES;
    }
    return nil;
}


+ (NSNumber*)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([currentAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        currentAuthorizationFlow = nil;
        return @YES;
    }
    return @NO;
}

@end
