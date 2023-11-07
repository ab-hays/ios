//
//  IBCUser.m
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/22/22.
//

#import "IBCUser.h"

@implementation IBCUser

@synthesize userName;
@synthesize internalID;
@synthesize emailAddress;
@synthesize password;
@synthesize lastLoginDate;
@synthesize fullName;
@synthesize mainPhone;

@synthesize timeZoneOffGMT;
@synthesize authCodeCount;

- (instancetype)init
{
    if (self = [super init])
    {
        
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.userName = [coder decodeObjectForKey:USER_USERNAME];
        self.internalID = [coder decodeObjectForKey:USER_INTERNALID];
        self.emailAddress = [coder decodeObjectForKey:USER_EMAIL_ADDRESS];
        self.password = [coder decodeObjectForKey:USER_TEMP_PASSWORD];
        self.lastLoginDate = [coder decodeObjectForKey:USER_LAST_LOGIN_DATE];
        self.fullName = [coder decodeObjectForKey:USER_FULLNAME];
        self.mainPhone = [coder decodeObjectForKey:USER_MAINPHONE];
        self.timeZoneOffGMT = [coder decodeIntForKey:USER_TIMEZONE];
        self.authCodeCount = [coder decodeIntForKey:USER_AUTHCODE_CNT];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.userName forKey:USER_USERNAME];
    [coder encodeObject:self.internalID forKey:USER_INTERNALID];
    [coder encodeObject:self.emailAddress forKey:USER_EMAIL_ADDRESS];
    [coder encodeObject:self.password forKey:USER_TEMP_PASSWORD];
    [coder encodeObject:self.lastLoginDate forKey:USER_LAST_LOGIN_DATE];
    [coder encodeObject:self.fullName forKey:USER_FULLNAME];
    [coder encodeObject:self.mainPhone forKey:USER_MAINPHONE];
    [coder encodeInt:self.timeZoneOffGMT forKey:USER_TIMEZONE];
    [coder encodeInt:self.authCodeCount forKey:USER_AUTHCODE_CNT];
}

@end
