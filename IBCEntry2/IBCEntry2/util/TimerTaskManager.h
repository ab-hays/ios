//
//  TimerTaskManager.h
//  Dollars&$ense
//
//  Created by Nicholas Pisarro on 2/19/12.
//  Copyright 2011 NP Associates, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPollingRoundCompletedNotification @"PollingRoundCompleted"

#define DEFAULT_POLLING_INTERVAL    2000.0      // 2 Seconds

typedef enum
{
	POLLER_NOT_RUNNING,
	POLLER_USING_TIMER,
	POLLER_USING_GCD
} pollerStates;

/* Modbus Generator time task manager.
 * This object runs under GCD and performs periodic tasks,
 *   such asking the generators to refresh themselves, and
 *   log files to emit records. */
@interface TimerTaskManager : NSObject
{
    NSTimeInterval      pollInterval;       // in Milliseconds
    
	pollerStates		pollerState;
    
    BOOL                GDCPollLock;        // We're only want one poll at a time.
	
	// For Grand Central Dispatch.
	dispatch_source_t	pollTimerGCD;		// (Not an objective C object.)
}

@property (nonatomic) pollerStates pollerState;

- (id)initWithPollingInterval:(NSTimeInterval)PollInMS;

// Starting & stopping polling using Grand Central Dispatch (GCD).
- (void)startGCDPolling;
- (void)stopGCDPolling;

- (void)pollGDCFire;        // (Internal—Move def. to .m file)

@end
