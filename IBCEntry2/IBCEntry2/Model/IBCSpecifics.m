//
//  IBCSpecifics.m
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/26/22.
//

#import "IBCSpecifics.h"

@implementation IBCSpecifics

@synthesize signalLookup;

- (instancetype)init
{
    if (self = [super init])
    {
        self.signalLookup = [NSMutableDictionary dictionaryWithCapacity:10];
        
        // (There has to be a better way to do this!)
        IBCCodeSignal *sig;
        sig = [[IBCCodeSignal alloc] initWithValues:@"8500FF00" strength:-50];
        self.signalLookup[sig.manufacturersCode] = sig;
        sig = [[IBCCodeSignal alloc] initWithValues:@"8500FF40" strength:-65];
        self.signalLookup[sig.manufacturersCode] = sig;
        sig = [[IBCCodeSignal alloc] initWithValues:@"8500FF80" strength:-75];
        self.signalLookup[sig.manufacturersCode] = sig;
        sig = [[IBCCodeSignal alloc] initWithValues:@"8500FFC0" strength:-200];
        self.signalLookup[sig.manufacturersCode] = sig;
    }
    
    return self;;
}

// Convert the Manufacturer's data into a hex string.
// (It would be nice to cache this somewhare.)
+ (NSString *)standardize:(NSData *)code
{
    NSMutableString *result = [NSMutableString stringWithCapacity:20];
    uint8_t *bytes = (uint8_t*)code.bytes;
    for(int i = 0; i < sizeof(bytes)+1; ++i)
    {
        NSString *resultString = [NSString stringWithFormat:@"%02lX", (unsigned long)bytes[i]];
        [result appendString:resultString];
    }
    
    // We're only interested in the first 4 bytes/8 digits.
    return [result substringToIndex:8];
}
- (BOOL)manuCodeValid:(NSData *)code
{
    return self.signalLookup[[IBCSpecifics standardize:code]] != nil;
}
- (BOOL)show:(NSData *)code
    withRSSI:(NSNumber *)RSSI
{
    // We use NSNumber objects since the RSSI is defined as one.
    NSString *wkgCode = [IBCSpecifics standardize:code];
    IBCCodeSignal *entry = self.signalLookup[wkgCode];
    
    if (!entry)
        return FALSE;
    NSNumber *minAsNumber = [NSNumber numberWithFloat:entry.minRSSI];
    
    NSComparisonResult result = [minAsNumber compare:RSSI];
    return result == NSOrderedSame || result == NSOrderedAscending;
}

@end

@implementation IBCCodeSignal

@synthesize manufacturersCode;
@synthesize minRSSI;

- (instancetype)initWithValues:(NSString *)code strength:(CGFloat)strength
{
    if (self = [super init])
    {
        self.manufacturersCode = code;
        self.minRSSI = strength;
    }
    
    return self;
}

@end
