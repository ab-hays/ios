//
//  WelcomeController.h
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 5/31/22.
//

#import <UIKit/UIKit.h>

@interface WelcomeController : UIViewController
    <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UILabel *welcomeLabel;
    IBOutlet UITableView *devTable;
    IBOutlet UIButton *scanRescanButton;
    
    BOOL    didThisAlready;
}

@property (readwrite, nonatomic)  BOOL didThisAlready;

- (IBAction)showSettings:(id)sender;

@end

@class BigColoredDot;

@interface IBCDeviceCell : UITableViewCell
{
    IBOutlet UILabel *devName;
    IBOutlet BigColoredDot *dot;
}

@property (strong, nonatomic) UILabel *devName;
@property (strong, nonatomic) BigColoredDot *dot;

@end

@interface BigColoredDot : UIView
{
    UIColor *dotColor;
}

@property (strong, nonatomic)  UIColor *dotColor;

@end
