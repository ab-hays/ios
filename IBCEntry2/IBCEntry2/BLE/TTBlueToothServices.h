//
//  TTBlueToothServices.h
//  TrainTetherApp
//
//  Created by Nicholas Pisarro on 2/17/16.
//  Copyright © 2016 Nicholas Pisarro, Jr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

// Intra program messages.
#define kTTBDeviceDiscoveredNotification      @"MessageDeviceDiscovered"
#define kTTBDeviceServicesHereNotification    @"MessageDeviceServicesHere"
#define kTTBConnectedForUARTNotification      @"MessqgeConnectedForUART"
#define		kUserInfoDiscoveredDevice         @"DiscoveredDeviceData" // TTBTDevice
#define kTTBRxDataArrivedNotification         @"MessageRxDataArrived"
#define kTTBMessageArrivedNotificaton         @"MessageMessageArrived"
#define kTTBTxDataSentNotification            @"MessageTxDataSent"
#define     kUserRxTxData                     @"RxTxData" // NSString

// Maximum Real Write Size.
#define MAX_REAL_BLUETOOTH_WRITE_SIZE       20

// Bluetooth UUIDs
#define SERVICE_UUID            @"DA2B84F1-6279-48DE-BDC0-AFBEA0226079"

// Characteristics UUIds
#define MODE_UUID               @"A87988B9-694C-479C-900E-95DFA6C00A24"
#define TX_UUID                 @"BF03260C-7205-4C25-AF43-93B1C299D159"
#define RX_UUID                 @"18CDA784-4BD3-4370-85BB-BFED91EC86AF"

// Asynchronouse Operations we want to perform.
typedef enum {
    TTANone,
    TTAScanPeripherals,
    TTAScanServices,
    TTAScanCharacteristics,
    TTAConnectForUart,
    TTAConnectForIBC,
    TTADisconnecting,
    TTASetupIBC,
    TTAWriting,
    TTAWritingMore,
    TTAWriteComplete,
    TTAReading,
} TTAsyncOps;

@class TTBTDevice;

@interface TTBlueToothServices : NSObject
    <CBCentralManagerDelegate>
{
    BOOL                poweredOn;
    TTAsyncOps          whatWeWant;
    
    TTBTDevice          *peripheralBeingConnected;
    
    CBCentralManager    *myCentralManager;
}

@property (readwrite, nonatomic) BOOL poweredOn;
@property (nonatomic, strong) CBCentralManager *myCentralManager;

+ (TTBlueToothServices *) sharedInstance;

- (void)scanForPeripherals;
- (void)stopScan;
- (void)scanForServices:(TTBTDevice *)ourPeripheral;
- (void)setupForUartCommunication:(TTBTDevice *)ourPeripheral;
- (void)setupForCommunition:(TTBTDevice *)ourPeripheral why:(TTAsyncOps)why;
- (void)disconnectDevice:(TTBTDevice *)ourPeripheral;

+ (CBUUID *)uartUUID;
+ (CBUUID *)modeCharacteristicUUID;
+ (CBUUID *)txCharacteristicUUID;
+ (CBUUID *)rxCharacteristicUUID;

@end

// (The UArt Service part of this object should either be a descendant or a separate object.)
@interface TTBTDevice : NSObject
    <CBPeripheralDelegate>
{
    TTAsyncOps      whatWeWant;

    CBPeripheral    *peripheral;
    NSDictionary    *advertisementData;
    NSNumber        *RSSI;

    // Put this in a descendant?
    BOOL            connectedForUart;
    NSMutableString *outBuffer;
    NSMutableString *messageGather;
    
    // For buffering output lines, when we are busy.
    NSMutableArray<NSString *>
                    *outGoingStack;
}

@property (nonatomic, readwrite) TTAsyncOps whatWeWant;

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSDictionary *advertisementData;
@property (nonatomic, strong) NSNumber *RSSI;

// Put this in a descendant?
@property (nonatomic, readwrite) BOOL connectedForUart;
@property (nonatomic, strong) NSMutableString *outBuffer;
@property (nonatomic, strong) NSMutableString *messageGather;
@property (atomic, strong) NSMutableArray<NSString *> *outGoingStack;

- (id)initWithPeripheral:(CBPeripheral *)peripheral
       advertisementData:(NSDictionary *)advertisementData
                    RSSI:(NSNumber *)RSSI;

- (void)scanForServices;
- (void)setupForUartCommunication;
- (void)setupForIBCCommunication;

// Reads and writes are always to Uart service.
- (void)writeString:(NSString *)command;
- (void)askForData;


@end
