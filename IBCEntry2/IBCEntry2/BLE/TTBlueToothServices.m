//
//  TTBlueToothServices.m
//  TrainTetherApp
//
//  Created by Nicholas Pisarro on 2/17/16.
//  Copyright © 2016 Nicholas Pisarro, Jr. All rights reserved.
//

#import "TTBlueToothServices.h"

@implementation TTBlueToothServices

@synthesize poweredOn;
@synthesize myCentralManager;

#pragma mark -
#pragma mark Singleton Methods

+ (TTBlueToothServices *)sharedInstance {
    
    static TTBlueToothServices *_sharedInstance;
    
    if(!_sharedInstance)
    {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            _sharedInstance = [[super allocWithZone:nil] init];
        });
    }
    
    return _sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {	
    
    return [self sharedInstance];
}


- (id)copyWithZone:(NSZone *)zone {
    return self;	
}

#if (!__has_feature(objc_arc))

- (id)retain {	
    
    return self;	
}

- (NSUInteger)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    
    return self;	
}
#endif

#pragma mark -
#pragma mark Custom Methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        poweredOn = FALSE;      // The manager will tell us when it's up.
        whatWeWant = TTANone;
        
        self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:nil];
    }
    
    return self;
}

- (void)scanForPeripherals
{
    // Don't try this if manager is not powered on.
    if (myCentralManager.state == CBCentralManagerStatePoweredOn)
        [self.myCentralManager scanForPeripheralsWithServices:@[TTBlueToothServices.uartUUID]
                                                      options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
    whatWeWant = TTAScanPeripherals;    
}

- (void)stopScan
{
    [self.myCentralManager stopScan];
    
    whatWeWant = TTANone;
}

- (void)scanForServices:(TTBTDevice *)ourPeripheral
{
    if (whatWeWant == TTAScanPeripherals)
        [self stopScan];
    
    peripheralBeingConnected = ourPeripheral;
    whatWeWant = TTAScanServices;
    
    [self.myCentralManager connectPeripheral:ourPeripheral.peripheral
                                     options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:[NSNumber numberWithBool:TRUE]}];
}

- (void)setupForUartCommunication:(TTBTDevice *)ourPeripheral
{
    [self setupForCommunition:ourPeripheral why:TTAConnectForUart];
}

- (void)setupForCommunition:(TTBTDevice *)ourPeripheral
                         why:(TTAsyncOps)why
{
    if (! ourPeripheral)
        return;
    
    if (whatWeWant == TTAScanPeripherals)
        [self stopScan];
    
    peripheralBeingConnected = ourPeripheral;
    whatWeWant = why;
    
    [self.myCentralManager connectPeripheral:ourPeripheral.peripheral
                                     options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:[NSNumber numberWithBool:TRUE]}];
}

// We are through with a perifpheral.
- (void)disconnectDevice:(TTBTDevice *)ourPeripheral
{
    // Once you start disconnecting, everything else stops!
    whatWeWant = TTADisconnecting;
    
    [self.myCentralManager cancelPeripheralConnection:ourPeripheral.peripheral];
}

+ (CBUUID *)uartUUID
{
    return [CBUUID UUIDWithString:SERVICE_UUID];
}
 + (CBUUID *)modeCharacteristicUUID
{
    return [CBUUID UUIDWithString:MODE_UUID];
}
+ (CBUUID *)txCharacteristicUUID
{
    return [CBUUID UUIDWithString:TX_UUID];
}
+ (CBUUID *)rxCharacteristicUUID
{
    return [CBUUID UUIDWithString:RX_UUID];
}

#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    BOOL newPoweredOn = central.state == CBCentralManagerStatePoweredOn;
    
    // If being powered up and we want to scan, reissule the request.
    if (! poweredOn && newPoweredOn &&
        whatWeWant == TTAScanPeripherals)
    {
        [self scanForPeripherals];
    }
    
    poweredOn = newPoweredOn;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@", (peripheral.name) ? peripheral.name : @"-nameless-");
    
    // Our object to hold the device data.
    TTBTDevice *ourDevice = [[TTBTDevice alloc] initWithPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    
    // Let the rest of the application know we have discovered this device.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTBDeviceDiscoveredNotification
                                                            object:self
                                                          userInfo:@{kUserInfoDiscoveredDevice:ourDevice}];
    });
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Make sure this is a peripheral of interest.
    if (peripheral == peripheralBeingConnected.peripheral)
    {
        // What are we doing next.
        switch (whatWeWant)
        {
            case TTAScanServices:
                [peripheralBeingConnected scanForServices];
                break;
                
            case TTAConnectForUart:
                [peripheralBeingConnected setupForUartCommunication];
                break;
                
            case TTAConnectForIBC:
                [peripheralBeingConnected setupForIBCCommunication];
                break;
                
            default:
                [self.myCentralManager cancelPeripheralConnection:peripheral];
        }
    }
}

- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(nullable NSError *)error
{
    // Message the failure.
}


@end

@implementation TTBTDevice

@synthesize whatWeWant;
@synthesize peripheral;
@synthesize advertisementData;
@synthesize RSSI;
@synthesize connectedForUart;
@synthesize outBuffer;
@synthesize messageGather;
@synthesize outGoingStack;

- (id)initWithPeripheral:(CBPeripheral *)peripheral
       advertisementData:(NSDictionary *)advertisementData
                    RSSI:(NSNumber *)RSSI
{
    if (self = [self init])
    {
        self.peripheral = peripheral;
        self.advertisementData = advertisementData;
        self.RSSI = RSSI;
        
        self.whatWeWant = TTANone;
        self.connectedForUart = FALSE;
    }
    
    return self;
}

- (void)scanForServices
{
    self.whatWeWant = TTAScanServices;
     
    // Cause the peripheral to discover all its services.
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
}

- (void)setupForUartCommunication
{
    self.whatWeWant = TTAConnectForUart;
    
    // Cause the peripheral to discover all the UART service.
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[[TTBlueToothServices uartUUID]]];
}

- (void)setupForIBCCommunication
{
    self.whatWeWant = TTAConnectForIBC;
    
    // Cause the peripheral to discover all the UART service.
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[[TTBlueToothServices uartUUID]]];
}

- (void)writeString:(NSString *)command
{
    // If we are busy, save the command.
    if (whatWeWant != TTAWriting && whatWeWant != TTAWritingMore)
    {
        [self.outBuffer setString:command];
    
        [self writePiece];
    }
    else
        [self.outGoingStack addObject:command];
 }

- (void)writePiece
{
    // Pick off the first 20 characters.
    NSRange nextRange = NSMakeRange(0,
                                    (self.outBuffer.length > MAX_REAL_BLUETOOTH_WRITE_SIZE) ? MAX_REAL_BLUETOOTH_WRITE_SIZE : self.outBuffer.length);
    NSString *first20 = [self.outBuffer substringWithRange:nextRange];
    [self.outBuffer deleteCharactersInRange:NSMakeRange(0, first20.length)];
    
    NSUInteger maxWrite = [self.peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithResponse];
    NSData *dataToGo = [first20 dataUsingEncoding:NSUTF8StringEncoding];
    if (dataToGo.length > MAX_REAL_BLUETOOTH_WRITE_SIZE)
        NSLog(@"Warning: Attempting to write too much data of %lu", (unsigned long)dataToGo.length);
    
    // find the UArt service
    for (CBService *theService in self.peripheral.services)
        if ([theService.UUID isEqual:[TTBlueToothServices uartUUID]])
        {
            // Find the transmit characteristic.
            CBCharacteristic *aCharacteristic;
            for (aCharacteristic in theService.characteristics)
                if ([aCharacteristic.UUID isEqual:[TTBlueToothServices txCharacteristicUUID]])
                {
                    if (self.outBuffer.length > 0)
                        self.whatWeWant = TTAWritingMore;
                    else
                        self.whatWeWant = TTAWriting;
                    
                    NSLog(@"Writing %lu bytes.", (unsigned long)dataToGo.length);
                    
                    // (We may be limited to sending only 20 characters at a time.)
                    self.peripheral.delegate = self;        // (Ditch ?)
                    [self.peripheral writeValue:dataToGo
                              forCharacteristic:aCharacteristic
                                           type:CBCharacteristicWriteWithResponse]; // (Test without?)
                    break;
                }
            
            break;
        }
}

- (void)askForData
{
    for (CBService *theService in self.peripheral.services)
        if ([theService.UUID isEqual:[TTBlueToothServices uartUUID]])
        {
            // Find the transmit characteristic.
            CBCharacteristic *aCharacteristic;
            for (aCharacteristic in theService.characteristics)
                if ([aCharacteristic.UUID isEqual:[TTBlueToothServices rxCharacteristicUUID]])
                {
                    self.whatWeWant = TTAReading;
                    
                    // (We may be limited to sending only 20 characters at a time.)
                    self.peripheral.delegate = self;        // (Ditch ?)
                    [self.peripheral readValueForCharacteristic:aCharacteristic];
                    break;
                }
            
            break;
        }
}

#pragma mark CBPeripheralDelegate

- (void)    peripheral:(CBPeripheral *)peripheral
   didDiscoverServices:(nullable NSError *)error
{
    if (peripheral != self.peripheral)
        return;
        
    switch (self.whatWeWant)
    {
        case TTAScanServices:
        {
            // Let the rest of the application know we have discovered this device's services.
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kTTBDeviceServicesHereNotification
                                                                    object:self
                                                                  userInfo:@{kUserInfoDiscoveredDevice:self}];
            });
        }
            break;
            
        case TTAConnectForUart:
        case TTAConnectForIBC:
        {
            // find the UArt service
            CBService *theService;
            for (theService in self.peripheral.services)
                if ([theService.UUID isEqual:[TTBlueToothServices uartUUID]])
                {
                    
                    // We need to find the UART Characteristics for this peripheral, so we can use them.
                    self.peripheral.delegate = self;
                    [self.peripheral discoverCharacteristics:nil forService:theService];
                    
                    break;
                }
        }
            break;
            
        default:
            break;
    }
}

- (void)                    peripheral:(CBPeripheral *)peripheral
  didDiscoverCharacteristicsForService:(CBService *)service
                                 error:(nullable NSError *)error
{
    if (error)
        return;
    
    switch (self.whatWeWant)
    {
        case TTAConnectForUart:
        {
            // Subscribe to changes to the rxCharacteristic.
            CBCharacteristic *aCharacteristic;
            for (aCharacteristic in service.characteristics)
                if ([aCharacteristic.UUID isEqual:[TTBlueToothServices rxCharacteristicUUID]])
                {
                    [self.peripheral setNotifyValue:YES
                                  forCharacteristic:aCharacteristic];
                    break;
                }
            
            // Set outselves up for 'Uartness'.
            self.connectedForUart = TRUE;
            self.outBuffer = [NSMutableString stringWithCapacity:256];
            self.messageGather = [NSMutableString stringWithCapacity:256];
            self.outGoingStack = [NSMutableArray arrayWithCapacity:10];
            
            // Send a notification that Uart is ready to go.
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kTTBConnectedForUARTNotification
                                                                    object:self
                                                                  userInfo:@{kUserInfoDiscoveredDevice:self}];
            });
        }
            break;
            
        case TTAConnectForIBC:
        {
            CBCharacteristic *foundCharacteristic = nil;
            
            // Subscribe to changes to the rxCharacteristic.
            CBCharacteristic *aCharacteristic;
            for (aCharacteristic in service.characteristics)
            {
                if ([aCharacteristic.UUID isEqual:TTBlueToothServices.modeCharacteristicUUID])
                    foundCharacteristic = aCharacteristic;
                if ([aCharacteristic.UUID isEqual:TTBlueToothServices.txCharacteristicUUID])
                {
                    [peripheral setNotifyValue:YES forCharacteristic:aCharacteristic];
                }
                
                if ([aCharacteristic.UUID isEqual:TTBlueToothServices.rxCharacteristicUUID])
                {
                    [peripheral setNotifyValue:YES forCharacteristic:aCharacteristic];
                }
            }
            
            // Set outselves up for 'Uartness'.
            self.connectedForUart = TRUE;
            self.outBuffer = [NSMutableString stringWithCapacity:256];
            self.messageGather = [NSMutableString stringWithCapacity:256];
            self.outGoingStack = [NSMutableArray arrayWithCapacity:10];
            
            // If the mode characteristic is found, tell the board to set up for UART communication.
            if (foundCharacteristic)
            {
                self.whatWeWant = TTASetupIBC;
                
                int n = 1;
                NSMutableData *byteData = [NSMutableData new];
                [byteData appendBytes:&n length:1];
                
                [self.messageGather setString:@""];
                [self.peripheral writeValue:byteData
                          forCharacteristic:foundCharacteristic
                                       type:CBCharacteristicWriteWithResponse];
            }
            
            // If we're finished send a notification that Uart is ready to go.
            if (self.whatWeWant == TTAConnectForIBC)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTTBConnectedForUARTNotification
                                                                        object:self
                                                                      userInfo:@{kUserInfoDiscoveredDevice:self}];
                });
        }
            break;
            
        default:
            break;
    }
}

// We log an error, if the disconnect failed.
- (void)        centralManager:(CBCentralManager *)central
       didDisconnectPeripheral:(CBPeripheral *)peripheral
                         error:(nullable NSError *)error
{
    if (error)
        NSLog(@"Error Attempting trying to disconnect: %@", error.localizedDescription);
    NSLog(@"Disconnect completed!");
    
    // We're finished.
    whatWeWant = TTANone;
}

- (void)                peripheral:(CBPeripheral *)peripheral
   didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                             error:(nullable NSError *)error
{
    if (error)
    {
        NSLog(@"Error Attempting to read data: %@", error.localizedDescription);
        return;
    }
    if (self.whatWeWant == TTASetupIBC)
    {
        // Gather what has come in until we hit a CR.
        NSString *valueAsStr = [[NSString alloc] initWithData:characteristic.value
                                                     encoding:NSUTF8StringEncoding];
        [self.messageGather appendString:valueAsStr];
        
        NSString *lastchar = [self.messageGather substringFromIndex:self.messageGather.length - 1];
        
        // If the last character is a '\r' we've got everything. Send it off.
        if ([lastchar  isEqual:@"\r"])
        {
            self.whatWeWant = TTANone;
            
            NSLog(@"Setup Data: %@", self.messageGather);
            
            // Dequeue the message.
            NSString *dequeued = [NSString stringWithString: self.messageGather];
            [self.messageGather deleteCharactersInRange:NSMakeRange(0, self.messageGather.length)];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kTTBConnectedForUARTNotification
                                                                    object:self
                                                                  userInfo:@{kUserInfoDiscoveredDevice:self,
                                                                             kUserRxTxData: dequeued}];
            });
        }
        
        return;
    }
    
    // Send a notification with the new rx Value.
    if (self.whatWeWant == TTAReading &&
        [characteristic.UUID isEqual:[TTBlueToothServices rxCharacteristicUUID]])
    {
        NSString *valueAsStr = [[NSString alloc] initWithData:characteristic.value
                                                     encoding:NSUTF8StringEncoding];
        
        // Send off the raw data.
        if (valueAsStr && valueAsStr.length > 0)
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kTTBRxDataArrivedNotification
                                                                    object:self
                                                                  userInfo:@{kUserInfoDiscoveredDevice:self, kUserRxTxData: valueAsStr}];
            });
        
        [self sendOffWholeLines:valueAsStr];
    }
    
    if ((self.whatWeWant == TTAWriting ||
         self.whatWeWant == TTAWritingMore ||
         self.whatWeWant == TTAWriteComplete) &&
        [characteristic.UUID isEqual:[TTBlueToothServices rxCharacteristicUUID]])
    {
        NSString *valueAsStr = [[NSString alloc] initWithData:characteristic.value
                                                     encoding:NSUTF8StringEncoding];
        
        // Send off the raw data.
        if (valueAsStr && valueAsStr.length > 0)
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kTTBRxDataArrivedNotification
                                                                    object:self
                                                                  userInfo:@{kUserInfoDiscoveredDevice:self, kUserRxTxData: valueAsStr}];
            });
        
        [self sendOffWholeLines:valueAsStr];
    }
}

- (void)sendOffWholeLines:(NSString *)strToAppend
{
    [self.messageGather appendString:strToAppend];
    
    // Gather up a whole line, to "\r", and send it off including the "\r".
    // We don't do anything, if we don't hit a "\r".
    NSRange lineRange = NSMakeRange(0, 0);
    for (int i = 0; i < self.messageGather.length; ++i)
    {
        unichar charToChect = [self.messageGather characterAtIndex:i];
        
        switch (charToChect) {
            case '\r':
            {
                lineRange.length = i + 1;
                NSString *line = [self.messageGather substringWithRange:lineRange];
                [self.messageGather deleteCharactersInRange:lineRange];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:kTTBMessageArrivedNotificaton
                                                                      object:self
                                                                    userInfo:@{kUserInfoDiscoveredDevice:self, kUserRxTxData: line}];
                });
                
                // We continue scanning, there may be more than one whole line buffered.
                lineRange.length = 0;           // Effectively starts over.
                i = -1;
            }
                
                break;
                
            default:
                break;
        }
    }
}

// Find out if the write succeeded.
- (void)                peripheral:(CBPeripheral *)peripheral
    didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                             error:(nullable NSError *)error
{
    if (error)
        NSLog(@"Write error: %@", error.localizedDescription);
    
    if (self.whatWeWant == TTAWritingMore)
    {
        [self writePiece];
    }
    
    // If we're continuing setting up the characteristic, signal we're done.
    else if (self.whatWeWant == TTAWriting)
    {
        // Check to see if there are more lines to go out.
        if (self.outGoingStack.count > 0)
        {
            self.outBuffer = [NSMutableString stringWithString:self.outGoingStack.firstObject];
            
            [self writePiece];
        }
        
        else {
            // Tell the rest of the app that the write completed.
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kTTBTxDataSentNotification
                                                                    object:self
                                                                  userInfo:@{kUserInfoDiscoveredDevice:self}];
            });
            
            whatWeWant = TTAWriteComplete;
        }
    }
}

@end
