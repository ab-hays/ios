//
//  SignUpController.h
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/23/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class IBCUser;

@interface IBCSignUpController : UIViewController
    <UITextFieldDelegate>
{
    IBOutlet UIScrollView       *scroller;
    IBOutlet UIView             *contentView;
    IBOutlet UILabel                *signupLabel;
    
    IBOutlet UITextField        *userIDField;
    IBOutlet UITextField        *nameField;
    IBOutlet UITextField        *emailField;
    IBOutlet UITextField        *passwordField;
    
    IBOutlet UIButton           *registerButton;
    
    IBCUser                     *editedUser;
}

@property (strong, nonatomic) IBCUser *editedUser;

@end

NS_ASSUME_NONNULL_END
