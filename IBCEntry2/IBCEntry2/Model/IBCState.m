//
//  IBCState.m
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/22/22.
//

#import "IBCState.h"
#import "IBCUser.h"
#import "IBCSpecifics.h"

@implementation IBCState

@synthesize currUser;
@synthesize lastLoginDate;
@synthesize predefinedUsers;
@synthesize authCode;
@synthesize userCode;
@synthesize devices;
@synthesize specifics;
@synthesize tMgr;

- (instancetype)init
{
    if (self = [super init])
    {
        self.currUser = nil;
        self.lastLoginDate = [NSDate date];
        self.predefinedUsers = [NSMutableArray arrayWithCapacity:20];
        self.authCode = @"";
        self.userCode = @"";
        self.devices = [NSMutableArray arrayWithCapacity:20];
        self.specifics = [[IBCSpecifics alloc] init];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.currUser = [coder decodeObjectForKey:IBC_CURR_USER];
        self.lastLoginDate = [coder decodeObjectForKey:IBC_LAST_LOGIN_DATE];
        self.predefinedUsers = [coder decodeObjectForKey:IBC_PREDEFINED_USERS];
        self.authCode = [coder decodeObjectForKey:IBC_GLOBAL_AUTHCODE];
        if (!self.authCode)
            self.authCode = @"";
        self.userCode = [coder decodeObjectForKey:IBC_GLOBAL_USERCODE];
        if (!self.userCode)
            self.userCode = @"";
        
        // (Duplicate?)
        self.devices = [NSMutableArray arrayWithCapacity:20];
        self.specifics = [[IBCSpecifics alloc] init];
    }
    
    if (self.predefinedUsers.count == 0)
        [self defineSampleUsers];
    
    return self;
}

+ (IBCState *)shared {

    static IBCState *_default;
    
    if(!_default)
    {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            _default = [[super allocWithZone:nil] init];
        });
    }

    return _default;
}

// Create predefined users, primarily to make Apple happy.
- (void)defineSampleUsers
{
    // (We could table drive this, but we're starting with only one users.)
    IBCUser *aUser;
    
    // test, pw: demo.
    aUser = [[IBCUser alloc] init];
    aUser.userName = @"test";
    aUser.emailAddress = @"support@npassociatesllc.com";
    aUser.password = @"demo";
    aUser.lastLoginDate = [NSDate date];
    aUser.fullName = @"James P. Smith";
    aUser.timeZoneOffGMT = -5;
    aUser.authCodeCount = 0;
    [self.predefinedUsers addObject:aUser];
    
    [self writeToLocalDefaults];
}

- (void)setFromState:(IBCState *)state
{
    self.currUser = state.currUser;
    self.lastLoginDate = state.lastLoginDate;
    self.predefinedUsers = state.predefinedUsers;
    self.authCode = state.authCode;
    self.userCode = state.userCode;
}

// You don't specify where defaults come from.
// Return FALSE if the defaults weren't found.
+ (IBCState *)readFromDefaults
{
    NSData *backupStateData = [[NSUserDefaults standardUserDefaults]
                               dataForKey:IBC_STATE_IN_DEFAULTS];
    
    if (backupStateData == nil)
        return FALSE;
    
    return [IBCState backupStateFromData:backupStateData];
}


// Defaults could be local to the user or global to the host.
-  (BOOL)writeToLocalDefaults
{
    [[NSUserDefaults standardUserDefaults] setObject:self.dataFromBackupState
                                              forKey:IBC_STATE_IN_DEFAULTS];
   
    return TRUE;
}

- (IBCUser *)userFromPredefined:(NSString *)userID
{
    for (IBCUser *user in self.predefinedUsers)
    {
        if ([userID caseInsensitiveCompare:user.userName] == NSOrderedSame)
            return user;
        if ([userID caseInsensitiveCompare:user.emailAddress] == NSOrderedSame)
            return user;
    }
    
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.currUser forKey:IBC_CURR_USER];
    [coder encodeObject:self.lastLoginDate forKey:IBC_LAST_LOGIN_DATE];
    [coder encodeObject:self.predefinedUsers forKey:IBC_PREDEFINED_USERS];
    [coder encodeObject:self.authCode forKey:IBC_GLOBAL_AUTHCODE];
    [coder encodeObject:self.userCode forKey:IBC_GLOBAL_USERCODE];
}

+ (nullable IBCState *)backupStateFromData:(NSData *)data
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (NSData *)dataFromBackupState
{
    NSError *error;
    return [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:NO error: &error];
}


@end
