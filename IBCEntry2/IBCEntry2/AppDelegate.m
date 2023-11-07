//
//  AppDelegate.m
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 5/31/22.
//

#import "AppDelegate.h"
#import "IBCState.h"
#import "TimerTaskManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Try to get the previous state.
    IBCState *prevState = [IBCState readFromDefaults];
    if (prevState)
        [IBCState.shared setFromState:prevState];
    
    // If there are no sample users, define them.
    if (IBCState.shared.predefinedUsers.count == 0)
        [IBCState.shared defineSampleUsers];
    
    IBCState.shared.lastLoginDate = [NSDate date];
    
    IBCState.shared.tMgr = [[TimerTaskManager alloc] initWithPollingInterval:1000]; // 1/second
    [IBCState.shared.tMgr startGCDPolling];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [IBCState.shared writeToLocalDefaults];
}

- (void)dealloc
{
    [IBCState.shared.tMgr stopGCDPolling];
}


@end
