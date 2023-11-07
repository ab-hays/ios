//
//  SignUpController.m
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 6/23/22.
//

#import "IBCSignUpController.h"
#import "IBCState.h"
#import "IBCUser.h"

@interface IBCSignUpController ()
{
    CGFloat originalScrollerHeight;
}
@end

@implementation IBCSignUpController

@synthesize editedUser;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scroller.contentSize = [emailField superview].frame.size;
    
    // For some reason, the scroller doesn't scroll unless we reinstall the content view.
    UIView *owner = [emailField superview];
    [owner removeFromSuperview];
    [scroller addSubview:owner];
    
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
    
    [scroller setContentSize:contentView.frame.size];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupFromEditedUser];
    originalScrollerHeight = scroller.frame.size.height;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.view endEditing:YES];
}

- (void)setupFromEditedUser
{
    if (editedUser)
    {
        userIDField.text = editedUser.userName;
        nameField.text = editedUser.fullName;
        emailField.text = editedUser.emailAddress;
        passwordField.text = editedUser.password;
        
        [registerButton setTitle:@"Save" forState:UIControlStateNormal];
        signupLabel.text = [NSString stringWithFormat:@"Editing %@", editedUser.userName];
    }
    else
        signupLabel.text = @"Sign up New User";
}

- (IBAction)register:(id)sender
{
    // Validate the fields, issue an alert or register the user.
    NSString *alertMsg = nil;
    
    if (userIDField.text == nil)
        alertMsg = @"User ID must be specified.";
    else if (userIDField.text.length < 4)
        alertMsg = @"User ID field must be be at least 4 characters.";
    else if ([userIDField.text containsString:@" "])
        alertMsg = @"User ID field must not contain blanks.";
    else if (emailField.text == nil || emailField.text.length == 0)
        alertMsg = @"An e-mail address is required for two factor authorization.";
    else if (passwordField.text == nil || passwordField.text.length < 4)
        alertMsg = @"A password must be specified that is at least 4 characters long.";
    
    if (alertMsg)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2" message:alertMsg preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            
        }];
        
        [alert addAction:OKAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    // Create of update the user.
    else
    {
        BOOL defining = FALSE;
        IBCUser *wkgUser;
        if (editedUser)
            wkgUser = editedUser;
        else
            wkgUser = [IBCState.shared userFromPredefined:userIDField.text];
        
        if (!wkgUser)
            defining = TRUE;
        if (IBCState.shared.currUser)
            wkgUser = IBCState.shared.currUser;
        else
        {
            wkgUser = [[IBCUser alloc] init];
            defining = TRUE;
        }
        
        // The current user may have become a copy of the one in the user list. Both need to be updated.
        if (! defining)
        {
            IBCUser *definedUser = [IBCState.shared userFromPredefined:wkgUser.userName];
            if (definedUser && wkgUser != definedUser)
            {
                definedUser.userName = userIDField.text;
                definedUser.fullName = nameField.text;
                definedUser.emailAddress = emailField.text;
                definedUser.password = passwordField.text;
            }
        }
        
        wkgUser.userName = userIDField.text;
        wkgUser.fullName = nameField.text;
        wkgUser.emailAddress = emailField.text;
        wkgUser.password = passwordField.text;
        
        if (defining)
            [IBCState.shared.predefinedUsers addObject:wkgUser];
        
        // Update user)
        [IBCState.shared writeToLocalDefaults];
        
        [self.navigationController popViewControllerAnimated:YES];
        
        [NSNotificationCenter.defaultCenter postNotificationName:USER_UPDATE_NOTIFICATION
                                                          object:nil
                                                        userInfo:@{UPDATED_USER:wkgUser}];
    }
}

- (IBAction)cancelButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - keyboard delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == userIDField)
    {
        [nameField becomeFirstResponder];
        [scroller scrollRectToVisible:nameField.frame animated:YES];
    }
    else if (textField == nameField)
    {
        [emailField becomeFirstResponder];
        [scroller scrollRectToVisible:emailField.frame animated:YES];
    }
    else if (textField == emailField)
    {
        [passwordField becomeFirstResponder];
        [scroller scrollRectToVisible:passwordField.frame animated:YES];
    }
    else if (textField == passwordField)
    {
        [self.view endEditing:YES];
        [scroller scrollRectToVisible:registerButton.frame animated:YES];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [scroller scrollRectToVisible:textField.frame animated:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beforeFrame = [scroller convertRect:scroller.bounds
                                        toView:scroller.window];
    CGRect wkgFrame = scroller.frame;
    wkgFrame.size.height = keyboardSize.origin.y - beforeFrame.origin.y;
    scroller.frame = wkgFrame;
    
    // For some reason, the scroller doesn't scroll unless we mess with the height.
    CGSize testSize = scroller.contentSize;
    testSize.height += 10;
    scroller.contentSize = testSize;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect wkgFrame = scroller.frame;
    wkgFrame.size.height = originalScrollerHeight;
    scroller.frame = wkgFrame;
}

@end
