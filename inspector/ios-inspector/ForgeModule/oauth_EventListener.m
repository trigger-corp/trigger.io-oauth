//
//  oauth_EventListener.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/08/02.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import "oauth_Delegate.h"
#import "oauth_EventListener.h"

extern NSMutableDictionary<NSString*, oauth_Delegate*> *DelegateMap;

@implementation oauth_EventListener

+ (NSNumber *)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"oauth_EventListener::willFinishLaunchingWithOptions -> %@", launchOptions);
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
        return @YES;
    }
    return nil;
}


+ (NSNumber*)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSDictionary *response = [url queryAsDictionary];
    if (response == nil) {
        [ForgeLog e:[NSString stringWithFormat:@"Could not determine response for authorization request: %@", url]];
        return @YES;
    }

    NSString *state = [response objectForKey:@"state"];
    if (state == nil) {
        [ForgeLog e:[NSString stringWithFormat:@"Could not determine state for authorization response: %@", response]];
        return @YES;
    }

    oauth_Delegate *delegate = [DelegateMap objectForKey:state];
    if (delegate == nil) {
        [ForgeLog e:[NSString stringWithFormat:@"Could not determine delegate for authorization response: %@", response]];
        return @YES;
    }
    [DelegateMap removeObjectForKey:state];

    if ([delegate.currentAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        delegate.currentAuthorizationFlow = nil;
    } else if ([response objectForKey:@"error_message"]) { // handle non-standard error responses (e.g. Facebook)
        [delegate.currentAuthorizationFlow cancel];
    }

    delegate.currentAuthorizationFlow = nil;
    return @YES;
}

@end
