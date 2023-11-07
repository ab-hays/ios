//
//  WelcomeController.m
//  IBCEntry2
//
//  Created by Nicholas Pisarro on 5/31/22.
//

#import "WelcomeController.h"
#import "SettingsController.h"
#import "IBCSignInController.h"
#import "TimerTaskManager.h"
#import "IBCState.h"
#import "IBCUser.h"
#import "IBCSpecifics.h"
#import "TTBlueToothServices.h"
#import "IBCCipher.h"

typedef enum {
    WS_None,
    WS_Connecting,
    WS_SendEncryptedUserCode,
    WS_WaitingForUserCodeReply,
} WelcomeState;

@interface WelcomeController ()
{
    BOOL            scanning;
    
    int             tickCtr;
    
    WelcomeState    state;
    
    IBCCipher       *cipherMgr;
    
    TTBTDevice      *selDev;
    NSString        *connectionResult;           // Should be 33 characters.
}

@end

@implementation WelcomeController

@synthesize didThisAlready;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cipherMgr = [[IBCCipher alloc] init];
     
    didThisAlready = FALSE;
    scanning = FALSE;
    
    // Set up notifications.
    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc addObserver:self selector:@selector(deviceFound:)
               name:kTTBDeviceDiscoveredNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(connectionCompleted:)
               name:kTTBConnectedForUARTNotification
             object:nil];
    // When a write completed.
    [nc addObserver:self
           selector:@selector(writeCompleted:)
               name:kTTBTxDataSentNotification
             object:nil];
    // When an individual line arrives.
    [nc addObserver:self
           selector:@selector(lineArrived:)
               name:kTTBMessageArrivedNotificaton
             object:nil];
    // The user has been updated.
    [nc addObserver:self
           selector:@selector(userUpdated:)
               name:USER_UPDATE_NOTIFICATION
             object:nil];
    // Timere ticks come on the main thread.
    [nc addObserver:self
           selector:@selector(timerTick:)
               name:kPollingRoundCompletedNotification
             object:nil];
    
    state = WS_None;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // If there is no user defined, bring up the new user dialog (once).
    if (IBCState.shared.currUser == nil && ! didThisAlready)
    {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        IBCSignInController *controller = [storyBoard instantiateViewControllerWithIdentifier:@"SignIn"];
        
        if (controller)
            [self.navigationController pushViewController:controller animated:TRUE];
        
        didThisAlready = true;
    }
    
    [self welcomeMsgUpdate];
}

#pragma mark - Device Communications.

- (void)startScan
{
    if (!scanning)
    {
        // Start with a fresh list.
        [IBCState.shared.devices removeAllObjects];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [TTBlueToothServices.sharedInstance scanForPeripherals];
        
        // Put up an alert if bluetooth is off.
        if (!TTBlueToothServices.sharedInstance.poweredOn && FALSE)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                           message:@"Bluetooth communication is turned off."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            }];
            
            [alert addAction:OKAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            scanning = TRUE;
            
            // Reset the device table.
            [IBCState.shared.devices removeAllObjects];
            [devTable reloadData];
            
            // Timeout to stop scan.
            tickCtr = 1;
            
            // Set up the scanning button.
            scanRescanButton.backgroundColor = UIColor.systemOrangeColor;
            [scanRescanButton setTitle:@"Scanning" forState:UIControlStateNormal];
        }
    }
}

- (void)stopScan
{
    if (scanning)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        scanning = FALSE;
        [TTBlueToothServices.sharedInstance stopScan];
        
        // Set up the scanning button.
        [scanRescanButton setTitle:@"Rescan" forState:UIControlStateNormal];
        scanRescanButton.backgroundColor = UIColor.systemGreenColor;
    }
}

// A device arrived.
- (void)deviceFound:(NSNotification *)notification
{
    TTBTDevice *dev = notification.userInfo[kUserInfoDiscoveredDevice];
    
    NSLog(@"RSSI: %ld",(long)dev.RSSI.integerValue);
    NSData *data_manufacturerkey = dev.advertisementData[CBAdvertisementDataManufacturerDataKey];
    
    // See if the device is approved before we add it to our list.
    // (Encapsulate this.)
    if (data_manufacturerkey.length > 0)
    {
        // All this is just diagnostic code copied from IBC Control.
        
        //manufacturer key : data to array conversion
        NSMutableArray *array_manufacturerkey =[[NSMutableArray alloc] init];
        uint8_t *bytes = (uint8_t*)data_manufacturerkey.bytes;
        NSMutableString *bytesStr= [NSMutableString stringWithCapacity:sizeof(bytes)*2];
        for(int i=0; i < sizeof(bytes)+1; ++i)
        {
            NSString *resultString = [NSString stringWithFormat:@"%02lx",(unsigned long)bytes[i]];
            [array_manufacturerkey addObject:resultString];
            [bytesStr appendString:resultString];
        }
        //********//
        
        // Hexa to binary conversion
        NSString *binary_String = [IBCCipher convertHexToBinary:[array_manufacturerkey objectAtIndex:3]];
        
        //Binary to decimal
        NSRange r = NSMakeRange(0, 2);
        NSString *substring_binary_string = [binary_String substringWithRange: r];

        long v = strtol([substring_binary_string UTF8String], NULL, 2);
        NSLog(@"%ld", v); //logs 13
        NSString * string_final_decimal = [NSString stringWithFormat:@"%ld",v];
        
        //Replace index of array
        NSLog(@"Manufacturer Key: %@",array_manufacturerkey);
        [array_manufacturerkey replaceObjectAtIndex:3 withObject:string_final_decimal];
        NSLog(@"%@",array_manufacturerkey);

        NSString *string_RSSI_Value = dev.RSSI.stringValue;
        
        
        // Meaty stuff
        // If it is approved, add it to the list.
        if ([IBCState.shared.specifics manuCodeValid:data_manufacturerkey])
        {
            [IBCState.shared.devices addObject:dev];
            [devTable reloadData];
        }
    }
}

- (void)connectionCompleted:(NSNotification *)notification
{
    // Decode the data that came in.
    NSString *receivedData = notification.userInfo[kUserRxTxData];
    if (receivedData != nil && receivedData.length == 33)
    {
        Byte blat[16];
        [IBCCipher convertHex:receivedData toBytes:blat];
        connectionResult = receivedData;
    }
    
    // If there is a queued string, write it now.
    if (state == WS_Connecting)
    {
        IBCState *st = IBCState.shared;
        NSString *stringConverted = [cipherMgr IBCEncryption:connectionResult
                                                    userCode:st.userCode
                                                    authCode:st.authCode];
        NSString *final_string1 = [NSString stringWithFormat:@"%@\r", stringConverted];
        [selDev writeString:final_string1];
        
        state = WS_SendEncryptedUserCode;
    }
    else
        state = WS_None;
}

- (void)writeCompleted:(NSNotification *)notification
{
    NSLog(@"Write completed.");
    
    // If we wrote a connecting string, get a reply back.
    if (state == WS_SendEncryptedUserCode)
        state = WS_WaitingForUserCodeReply;
    else
        state = WS_None;
}

- (void)lineArrived:(NSNotification *)notification
{
    NSString *line = notification.userInfo[kUserRxTxData];
    
    // Trim off the trailing 'CR'.
    line = [line substringToIndex:line.length - 1];
    
    NSLog(@"line arrived: %@", line);
    
    // Based on what we're waiting for and what we got, take action.
    switch (state) {
        case WS_WaitingForUserCodeReply:
            if ([line isEqual:@"OK"])
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                               message:@"Sucessful transmission"
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                }];
                
                [alert addAction:OKAction];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
            else if ([line isEqual:@"NOK"])
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                               message:@"Transmission failed. Possibly wrong Authorization code or User Code."
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                }];
                
                [alert addAction:OKAction];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
            
            // We're done, disconnect from the device.
            [TTBlueToothServices.sharedInstance disconnectDevice:selDev];
            state = WS_None;
            
            break;
             
        default:
            break;
    }
}

- (void)userUpdated:(NSNotification *)notification
{
    [self welcomeMsgUpdate];
}

- (void)welcomeMsgUpdate
{
    if (IBCState.shared.currUser)
    {
        IBCUser *user = IBCState.shared.currUser;
        NSString *nameToUse;
        if (!user)
            nameToUse = @"unknown";
        else if (user.fullName.length > 0)
            nameToUse = user.fullName;
        else
            nameToUse = user.userName;
        
        welcomeLabel.text = [NSString stringWithFormat:@"Welcome\n%@", nameToUse];
        welcomeLabel.hidden = NO;
        
        [self startScan];
    }
    else
        welcomeLabel.hidden = YES;
}

// These come in on the main thread.
- (void)timerTick:(NSNotification *)notification
{
    // NSLog(@"- Tick -");
    
    if (--tickCtr < 0)
    {
        // If scanning, stop the scan.
        if (scanning)
            [self stopScan];
        
        // If doing something else, shut down the device.
        if (state != WS_None)
        {
            [TTBlueToothServices.sharedInstance disconnectDevice:selDev];
            state = WS_None;
            
            // Tell the user something went wrong.
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                           message:@"No response. Make sure you have entered the proper User and Authorization codes."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            }];
            
            [alert addAction:OKAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

#pragma mark - Actions

- (IBAction)showSettings:(id)sender
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SettingsController *controller = [storyBoard instantiateViewControllerWithIdentifier:@"Settings"];
    
    [self.navigationController pushViewController:controller animated:TRUE];
}

- (IBAction)scanRescan:(id)sender
{
    if (scanning)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                       message:@"Scanning for Devices…"
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *stopAction = [UIAlertAction actionWithTitle:@"Stop"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self stopScan];
        }];
        
        UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        }];
        
        [alert addAction:stopAction];
        [alert addAction:continueAction];
        
        /* Looks like we'll ignore clicks to stop the rescan since rhw discovery
         * timeout is only 1 second. */
        // [self presentViewController:alert animated:YES completion:nil];
    }
    else
        [self startScan];
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)   tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return IBCState.shared.devices.count;
}

- (CGFloat)     tableView:(UITableView *)tableView
  heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)   tableView:(UITableView *)tableView
            cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IBCDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"devCell"];
    
    TTBTDevice *dev = IBCState.shared.devices[indexPath.row];
    
    // Knock of the first 3 characters.
    NSString *wkgName = dev.advertisementData[@"kCBAdvDataLocalName"];
    wkgName = [[wkgName substringFromIndex:3] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    
    cell.devName.text = wkgName;
    // cell.devStrength.text = [NSString stringWithFormat:@"%@db", dev.RSSI.stringValue];
    
    // We show a red or green dot depending on the signal strength & manufacturer's code.
    NSData *data_manufacturerkey = dev.advertisementData[CBAdvertisementDataManufacturerDataKey];
   if ([IBCState.shared.specifics show:data_manufacturerkey withRSSI:dev.RSSI])
       cell.dot.dotColor = UIColor.greenColor;
    else
        cell.dot.dotColor = UIColor.redColor;
    [cell.dot setNeedsDisplay];
    
    return cell;
}

// You can not select items that don't have the required signal strength.
// (Possibly put up an alert saying what the problem is.)¥
- (BOOL)                tableView:(UITableView *)tableView
    shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Look up the device and confirm that it has the required signal strength.
    if (IBCState.shared.devices.count == 0)
        return FALSE;                           // Shouldn't happen!
    
    TTBTDevice *dev = IBCState.shared.devices[indexPath.row];
    NSData *data_manufacturerkey = dev.advertisementData[CBAdvertisementDataManufacturerDataKey];
    return [IBCState.shared.specifics show:data_manufacturerkey withRSSI:dev.RSSI];
}

// The user picked on a device. We need to communicate with it.
- (void)        tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Stop the scan.
    [self stopScan];
    
    // We need auth & user codes in order to communicate.
    IBCState *st = IBCState.shared;
    if ((st.authCode && st.authCode.length != 8 && st.authCode.length !=  0) ||
        !st.userCode || st.userCode.length != 12)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IBC Entry 2"
                                                                       message:@"We need proper Authorization and User codes to be able to connect to the device."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        }];
        
        [alert addAction:OKAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        // Note the device we've picked.
        selDev = IBCState.shared.devices[indexPath.row];
        
        // Fire up a connections and get the basic info back.
        state = WS_Connecting;                  // We can't do anything until this finishes.
        tickCtr = 2;                            // 2 second timeout
        [TTBlueToothServices.sharedInstance setupForCommunition:selDev
                                                            why:TTAConnectForIBC];
    }
    
    // Possibly after activation, deselect the row.
    // (Do this later.)
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

@end

@implementation IBCDeviceCell

@synthesize devName;
@synthesize dot;

- (instancetype)init
{
    if (self = [super init])
    {
        
    }
    
    return self;
}

@end

@implementation BigColoredDot

@synthesize dotColor;

- (void)drawRect:(CGRect)rect
{
    // It may not be set yet.
    if (self.dotColor)
    {
        CAShapeLayer *circle = [CAShapeLayer layer];
        
        [circle setPath:[[UIBezierPath bezierPathWithOvalInRect:self.bounds] CGPath]];
        [circle setStrokeColor:[[UIColor clearColor] CGColor]];
        [circle setFillColor:dotColor.CGColor];
        
        [self.layer addSublayer:circle];
    }
    
    [super drawRect:rect];
}

@end
