//
//  IBCSpecifics.h
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/26/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class IBCCodeSignal;

@interface IBCSpecifics : NSObject
{
    NSMutableDictionary<NSString *, IBCCodeSignal *>
                    *signalLookup;      // by manufacturersCode
}

@property (strong, nonatomic) NSMutableDictionary<NSString *, IBCCodeSignal *> *signalLookup;

+ (NSString *)standardize:(NSData *)code;
- (BOOL)manuCodeValid:(NSData *)code;
- (BOOL)show:(NSData *)code
    withRSSI:(NSNumber *)RSSI;

@end

@interface IBCCodeSignal : NSObject
{
    NSString    *manufacturersCode;
    CGFloat     minRSSI;
}

@property (strong, nonatomic) NSString *manufacturersCode;
@property (readwrite, nonatomic) CGFloat minRSSI;

- (instancetype)initWithValues:(NSString *)code
                      strength:(CGFloat)strength;

@end

NS_ASSUME_NONNULL_END
