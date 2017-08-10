#import "oauth_Delegate.h"
#import "oauth_EventListener.h"

extern id<OIDAuthorizationFlowSession> currentAuthorizationFlow; // TODO not ideal

@implementation oauth_EventListener

+ (NSNumber*)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"oauth_EventListener::openURL -> %@", url);

    // Sends the URL to the current authorization flow (if any) which will process it if it relates to
    // an authorization response.
    if ([currentAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        currentAuthorizationFlow = nil;
        NSLog(@"oauth_EventListener::openURL -> YES");
        return @YES;
    }

    return @NO;
}

+ (NSNumber *)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
        return @YES;
    }

    return nil;
}


@end
