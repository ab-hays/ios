//
//  TimerTaskManager.m
//  Dollars&$ense
//
//  Created by Nicholas Pisarro on 2/19/12.
//  Copyright 2011 NP Associates, LLC. All rights reserved.
//

#import "TimerTaskManager.h"

@implementation TimerTaskManager

@synthesize pollerState;

- (id)initWithPollingInterval:(NSTimeInterval)PollInMS
{
    if (self = [super init])
    {
		pollInterval = PollInMS / 1000;      // ms->ns
		
		pollerState = POLLER_NOT_RUNNING;
        GDCPollLock = false;
	}
	
	return self;
}
// Starting & stopping polling using Grand Central Dispatch (GCP).
- (void)startGCDPolling
{
	pollTimerGCD = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
	
	if (pollTimerGCD)
	{
        GDCPollLock = false;        // Reset the lock.
        
		dispatch_source_set_timer(pollTimerGCD,
								  dispatch_walltime(NULL, pollInterval * NSEC_PER_SEC),
								  pollInterval * NSEC_PER_SEC, 
								  pollInterval / 5.0 * NSEC_PER_SEC);
		dispatch_source_set_event_handler(pollTimerGCD, ^{[self pollGDCFire];});
		dispatch_resume(pollTimerGCD);
		
		pollerState = POLLER_USING_GCD;
	}
}

- (void)stopGCDPolling
{
	dispatch_source_cancel(pollTimerGCD);
	
	pollerState = POLLER_NOT_RUNNING;
}

- (void)pollGDCFire
{
    // We only want one poller task active at a time. We aren't too concerned about
    // race conditions. As long as we don't have too many of these running.
    if (GDCPollLock)
        return;
    GDCPollLock = true;
    
    // Do work here we want to accomplish on each polling round.
    
    
    // Send a notification out that we've finished a polling round.
    [self performSelectorOnMainThread:@selector(sendPollingRoundCompletedNotification)
                           withObject:nil
                        waitUntilDone:YES];
    
    GDCPollLock = false;
}

- (void)sendPollingRoundCompletedNotification
{
    // Send a message notifying everyone this polling round has completed.
    [[NSNotificationCenter defaultCenter]
     postNotification:[NSNotification notificationWithName:kPollingRoundCompletedNotification
                                                    object:self]];
}

- (void)dealloc
{
    // [self stopGCDPolling];
}

@end
