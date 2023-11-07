//
//  SettingsController.m
//  BLE_App
//
//  Created by Nicholas Pisarro on 6/13/22.
//  Copyright © 2022 Atinderjit Kaur. All rights reserved.
//

#import "SettingsController.h"
#import "WelcomeController.h"
#import "IBCSignUpController.h"
#import "IBCState.h"
#import "IBCUser.h"

// Not used delete!
@interface SettingsController ()
{
    CGFloat originalScrollerHeight;
}
@end

@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    originalScrollerHeight = scroller.frame.size.height;
    scroller.contentSize = [authCodeField superview].frame.size;
   
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // Keyboard show & hide events, to make room for it.
    [nc addObserver:self
           selector:@selector(keyboardWillShow:)
               name:UIKeyboardWillShowNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(keyboardWillHide:)
               name:UIKeyboardWillHideNotification
             object:nil];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupFields];
}

- (void)setupFields
{
    IBCState *st = IBCState.shared;
    
    authCodeField.text = st.authCode;
    if (st.userCode.length != 12)
    {
        userCodeField1.text = @"";
        userCodeField2.text = @"";
    }
    else
    {
        userCodeField1.text = [st.userCode substringToIndex:2];
        userCodeField2.text = [st.userCode substringFromIndex:2];
    }
    userCodeField1.placeholder = @"00";
    userCodeField2.placeholder = @"0123456789";
    
    if (st.currUser)
        [editButton setTitle:@"Edit User…" forState:UIControlStateNormal]; 
    else
        [editButton setTitle:@"Login…" forState:UIControlStateNormal]; 
    [logoutButton setEnabled:st.currUser];
}

- (BOOL)confirmFields
{
    // Validate the fields, issue an alert or register the user.
    NSString *alertMsg = nil;
    
    if (authCodeField.text.length != 8 && authCodeField.text.length != 0)
        alertMsg = @"Authorization code must be 8 characters or empty.";
    
    else if (userCodeField1.text.length != 2)
        alertMsg = @"First user code field should be 2 digits long.";
        
    else if (userCodeField2.text.length != 10)
        alertMsg = @"Second user code field should be 10 digits long.";
    
    if (alertMsg)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                       message:alertMsg
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            
        }];
        
        [alert addAction:OKAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return NO;
    }
    
    else
        return YES;
}


#pragma mark - Actions

- (IBAction)save:(id)sender
{
    if ([self confirmFields])
    {
        int changesLeft = MAX_CURRENT_AUTHCODE_CHANGES - IBCState.shared.currUser.authCodeCount;
        
        // Present an alert telling the user they have no changes left.
        if (changesLeft <= 0)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                           message:@"I'm sorry, you can't make any more changes to Authorization or user code. Refer to IBC Support."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"Got It!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
            {
                [self.view endEditing:YES];
                [self.navigationController popViewControllerAnimated:true];
            }];
            
            [alert addAction:OKAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            // Present an alert telling the user how many changes they have left.
            NSString *chgStr;
            if (changesLeft == 1)
                chgStr = @"1 change";
            else
                chgStr = [NSString stringWithFormat:@"%d changes", changesLeft];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                           message:[NSString stringWithFormat:@"You only have %@ left, do you wish to continue with this change?", chgStr]
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
            {
                IBCState *st = IBCState.shared;
                
                st.authCode = self->authCodeField.text;
                st.userCode = [NSString stringWithFormat:@"%@%@", self->userCodeField1.text, self->userCodeField2.text];
                
                // Use up a change count.
                ++IBCState.shared.currUser.authCodeCount;
                
                [st writeToLocalDefaults];
                
                [self.view endEditing:YES];
                [self.navigationController popViewControllerAnimated:true];
            }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
            {
                [self.view endEditing:YES];
                [self.navigationController popViewControllerAnimated:true];
            }];
            
            [alert addAction:OKAction];
            [alert addAction:cancelAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (IBAction)cancel:(id)sender
{
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:true];
}
- (IBAction)editClicked:(UIButton *)sender
{
    // Login state.
    if (! IBCState.shared.currUser)
    {
        WelcomeController *wc = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
        // (Do a class test here to make sure we really have a WelcomeController.)
        wc.didThisAlready = FALSE;
        
        // We're done with this screen, bring up the login screen.
        [self.view endEditing:YES];
        [self.navigationController popViewControllerAnimated:true];
    }
    else
    {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        IBCSignUpController *controller = [storyBoard instantiateViewControllerWithIdentifier:@"SignUp"];
        
        if (controller)
        {
            controller.editedUser = IBCState.shared.currUser;
            [self.navigationController popViewControllerAnimated:TRUE];
            [self.navigationController pushViewController:controller animated:TRUE];
        }
    }
}

- (IBAction)logoutClicked:(UIButton *)sender
{
    IBCState *st = IBCState.shared;
    
    st.currUser = nil;
    [st writeToLocalDefaults];
    
    WelcomeController *wc = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
    // (Do a class test here to make sure we really have a WelcomeController.)
    wc.didThisAlready = FALSE;
    
    // We're done with this screen, bring up the login screen.
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:true];
}

#pragma mark - Keyboard delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == authCodeField)
    {
        [userCodeField1 becomeFirstResponder];
        [scroller scrollRectToVisible:userCodeField1.frame animated:YES];
    }
    else if (textField == userCodeField1)
    {
        [userCodeField2 becomeFirstResponder];
        [scroller scrollRectToVisible:userCodeField2.frame animated:YES];
    }
    else if (textField == userCodeField2)
    {
        [self.view endEditing:YES];
    }
    
    return YES;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboarfSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

    CGRect wkgFrame = scroller.frame;
    wkgFrame.size.height = originalScrollerHeight + scroller.frame.origin.x - keyboarfSize.height;
    scroller.frame = wkgFrame;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect wkgFrame = scroller.frame;
    wkgFrame.size.height = originalScrollerHeight;
    scroller.frame = wkgFrame;
}

@end
