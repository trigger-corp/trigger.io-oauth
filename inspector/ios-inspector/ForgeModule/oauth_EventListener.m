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
        return @NO;
    }

    NSLog(@"oauth_EventListener::openURL -> %@ -> %@ -> RESPONSE: %@", DelegateMap, url, response);

    NSString *state = [response objectForKey:@"state"];
    if (state == nil) {
        [ForgeLog e:[NSString stringWithFormat:@"Could not determine state for authorization response: %@", response]];
        return @NO;
    }

    oauth_Delegate *delegate = [DelegateMap objectForKey:state];
    if (delegate == nil) {
        [ForgeLog e:[NSString stringWithFormat:@"Could not determine delegate for authorization response: %@ -> %@", response, DelegateMap]];
        return @NO;
    }
    [DelegateMap removeObjectForKey:state];


    if ([delegate.currentAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        // success
        NSLog(@"SUCCESS");
        delegate.currentAuthorizationFlow = nil;
        return @YES;
    }

    if ([response objectForKey:@"error_message"]) { // handle non-standard error responses (e.g. Facebook)
        [delegate.currentAuthorizationFlow cancel];
        delegate.currentAuthorizationFlow = nil;
        NSLog(@"WTF?");

    } else {
        delegate.currentAuthorizationFlow = nil;
        NSLog(@"HUH?");
    }

    return @NO;
}

/* When Google works:
 URL: com.googleusercontent.apps.627734613405-irkg4q6dbq01h0so0ltb17f9kgc4ubfn:/oauth2redirect?state=9qivIYlLvJe9sB5iinFFGh7QmshGWeq1IX6P2ajjcgg&code=4/IwpLHs47oOReLsCkdDTB1-lLbqmyoj9swAfM0sVFhYw#

 RESPONSE: {
     code = "4/IwpLHs47oOReLsCkdDTB1-lLbqmyoj9swAfM0sVFhYw";
     state = 9qivIYlLvJe9sB5iinFFGh7QmshGWeq1IX6P2ajjcgg;
 }
 */

/* Facebook gives:
 URL:  net.openid.appauth.demo://oauth2redirect?code=AQDFapdNrILJ1LQaVHI2parBxCfwvCxrcvsdc4U677WTRzhDjUQfZwcJMFmkiRzlpJjClRT30FTh7UmiQG2Qv0gkTk_AkwbIxgLWDI5trj05aSY3vbU3Jt5QE0s0CVToZ9l2r-3vteU1mh0AX-GcPlTSojvXkjyxA5WS89Itznhg0YEmJL3xtJFWC6Gn5IG8PiOJi1DW1PjoZKraGR1b8edO_wbaUYKMjlPRJGH5UfJBWunNmyrujBnn0f5kfJsm9_3nO3VyVXcrciqXy6uc32J7y-zRNVS2TW4VssKs2P0qSUSGKT8ZTOW_XK06-6yHMaAqRxfuAzrUNWBmbOhTs_4q&state=SEmWGOz-c_HeSM5H1FL6ZGgGhEqqNikVN0INOgojTBI#_=_ ->

 RESPONSE: {
    code = "AQDFapdNrILJ1LQaVHI2parBxCfwvCxrcvsdc4U677WTRzhDjUQfZwcJMFmkiRzlpJjClRT30FTh7UmiQG2Qv0gkTk_AkwbIxgLWDI5trj05aSY3vbU3Jt5QE0s0CVToZ9l2r-3vteU1mh0AX-GcPlTSojvXkjyxA5WS89Itznhg0YEmJL3xtJFWC6Gn5IG8PiOJi1DW1PjoZKraGR1b8edO_wbaUYKMjlPRJGH5UfJBWunNmyrujBnn0f5kfJsm9_3nO3VyVXcrciqXy6uc32J7y-zRNVS2TW4VssKs2P0qSUSGKT8ZTOW_XK06-6yHMaAqRxfuAzrUNWBmbOhTs_4q";
     state = "SEmWGOz-c_HeSM5H1FL6ZGgGhEqqNikVN0INOgojTBI";
 }
 */


@end
