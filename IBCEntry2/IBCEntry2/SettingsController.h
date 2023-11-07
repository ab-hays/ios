//
//  SettingsController.h
//  BLE_App
//
//  Created by Nicholas Pisarro on 6/13/22.
//  Copyright © 2022 Atinderjit Kaur. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Not used delete!
@interface SettingsController : UIViewController
    <UITextFieldDelegate>
{
    IBOutlet UIScrollView       *scroller;
    
    IBOutlet UITextField        *authCodeField;
    IBOutlet UITextField        *userCodeField1;
    IBOutlet UITextField        *userCodeField2;
    
    IBOutlet UIButton           *editButton;
    IBOutlet UIButton           *logoutButton;
}

@end

NS_ASSUME_NONNULL_END
