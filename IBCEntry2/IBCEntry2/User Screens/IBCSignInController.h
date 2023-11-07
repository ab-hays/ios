//
//  IBCSignInController.h
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/23/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBCSignInController : UIViewController
    <UITextFieldDelegate>
{
    IBOutlet UIScrollView       *scroller;
    
    IBOutlet UITextField        *userEmailField;
    IBOutlet UITextField        *passwordField;
    
    IBOutlet UIButton           *loginButton;
}

@end

NS_ASSUME_NONNULL_END
