//
//  IBCSignInController.m
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/23/22.
//

#import "IBCSignInController.h"
#import "IBCSignUpController.h"
#import "IBCState.h"
#import "IBCUser.h"

@interface IBCSignInController ()
{
    CGFloat originalScrollerHeight;
}
@end

@implementation IBCSignInController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    originalScrollerHeight = scroller.frame.size.height;
    scroller.contentSize = [userEmailField superview].frame.size;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // We want to get notified if a user was created/updated.
    [nc addObserver:self
           selector:@selector(userUpdated:)
               name:USER_UPDATE_NOTIFICATION
             object:nil];
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    [self.view endEditing:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void)userUpdated:(NSNotification *)notification
{
    // Pick up the user.
    IBCUser *updatedUser = notification.userInfo[UPDATED_USER];
    if (updatedUser)
    {
        userEmailField.text = updatedUser.userName;
        passwordField.text = updatedUser.password;
    }
}

- (IBAction)newUser:(id)sender
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    IBCSignUpController *controller = [storyBoard instantiateViewControllerWithIdentifier:@"SignUp"];
    
    if (controller)
        [self.navigationController pushViewController:controller animated:TRUE];
}

- (IBAction)login:(id)sender
{
    // Look in our user list.
    IBCUser *wkgUser = [IBCState.shared userFromPredefined:userEmailField.text];
    
    // TEMP: We only know how to confirm the current user.
    if (!wkgUser ||
        [wkgUser.password compare:passwordField.text] != NSOrderedSame)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                       message:@"Can't find user."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        }];
        
        [alert addAction:OKAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        IBCState.shared.currUser = wkgUser;
        [IBCState.shared writeToLocalDefaults];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)forgotPassword:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                   message:@"We don't know how to recover a password yet."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
    }];
    
    [alert addAction:OKAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - keyboard delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == userEmailField)
    {
        [passwordField becomeFirstResponder];
        [scroller scrollRectToVisible:passwordField.frame animated:YES];
    }
   else if (textField == passwordField)
    {
        [self.view endEditing:YES];
        [scroller scrollRectToVisible:loginButton.frame animated:YES];
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
