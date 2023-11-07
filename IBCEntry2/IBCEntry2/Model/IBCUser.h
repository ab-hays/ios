//
//  IBCUser.h
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/22/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define USER_USERNAME           @"userName"
#define USER_INTERNALID         @"internalID"
#define USER_EMAIL_ADDRESS      @"emailAddress"
#define USER_TEMP_PASSWORD      @"tempPassword"
#define USER_LAST_LOGIN_DATE    @"lastLoginDate"
#define USER_FULLNAME           @"fullName"
#define USER_MAINPHONE          @"mainPhone"
#define USER_TIMEZONE           @"timezoneOffset"
#define USER_AUTHCODE_CNT       @"authCodeCount"

#define MAX_CURRENT_AUTHCODE_CHANGES    2

@interface IBCUser : NSObject
    <NSCoding>
{
    NSString        *userName;              // The visible User ID
    NSString        *internalID;            // Internal UserID on backing store
    NSString        *emailAddress;
    
    NSString        *password;              // (May not be stored here in the future.)
    
    NSDate          *lastLoginDate;
    
    // Additional information about the user, stored in mySQL
    NSString        *fullName;
    NSString        *mainPhone;
    
    int             timeZoneOffGMT;
    
    int             authCodeCount;
}

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *internalID;
@property (strong, nonatomic) NSString *emailAddress;
@property (strong, nonatomic)  NSString *password;
@property (strong, nonatomic) NSDate *lastLoginDate;
@property (strong, nonatomic) NSString *fullName;
@property (strong, nonatomic) NSString *mainPhone;

@property (readwrite, nonatomic) int timeZoneOffGMT;
@property (readwrite, nonatomic) int authCodeCount;

@end

NS_ASSUME_NONNULL_END
