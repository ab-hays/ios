//
//  IBCState.h
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/22/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Program notifications.
#define USER_UPDATE_NOTIFICATION        @"userUpdate"
#define     UPDATED_USER                @"user"

// NSCpder fields.
#define IBC_STATE_IN_DEFAULTS       @"ibcState"
#define IBC_CURR_USER               @"currUser"
#define IBC_LAST_LOGIN_DATE         @"lastLoginDate"
#define IBC_GLOBAL_AUTHCODE         @"globalAuthCode"
#define IBC_GLOBAL_USERCODE         @"globalUserCode"
#define IBC_PREDEFINED_USERS        @"predefinedUsers"

@class IBCUser;
@class TTBTDevice;
@class IBCSpecifics;
@class TimerTaskManager;

@interface IBCState : NSObject
    <NSCoding>
{
    IBCUser         * _Nullable currUser;
    NSDate          *lastLoginDate;
    
    NSMutableArray<IBCUser *>
                    *predefinedUsers;
    
    // These may move.
    NSString        *authCode;
    NSString        *userCode;
    
    // Not saved.
    NSMutableArray<TTBTDevice *>
                    *devices;
    
    // Handle infor.
    IBCSpecifics    *specifics;
    
    TimerTaskManager *tMgr;
}

@property (strong, nonatomic) IBCUser * _Nullable currUser;
@property (strong, nonatomic) NSDate *lastLoginDate;
@property (strong, nonatomic) NSMutableArray<IBCUser *> *predefinedUsers;
@property (strong, nonatomic) NSString *authCode;
@property (strong, nonatomic) NSString *userCode;
@property (strong, nonatomic) NSMutableArray<TTBTDevice *> *devices;
@property (strong, nonatomic) IBCSpecifics *specifics;;
@property (strong, nonatomic) TimerTaskManager *tMgr;

+ (IBCState *)shared;
- (void)setFromState:(IBCState *)state;
- (void)defineSampleUsers;

+ (nullable IBCState *)readFromDefaults;
- (BOOL)writeToLocalDefaults;
- (IBCUser *)userFromPredefined:(NSString *)userID;

@end

NS_ASSUME_NONNULL_END
