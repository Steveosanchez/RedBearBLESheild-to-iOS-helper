//
//  BLEManagerController.m
//  BLE Test
//
//  Created by Steve_Sanchez on 1/9/14.
//  Copyright (c) 2014 Apargo LLC. All rights reserved.
//

#import "BLEManagerController.h"
#import "BLEConstants.h"



@interface BLEManagerController ()<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *activePeripheral;
@property (unsafe_unretained, nonatomic) BOOL isConnected;
@property (unsafe_unretained, nonatomic) BOOL isDigitalPinSendTurnedOn;
@property (unsafe_unretained, nonatomic) BOOL isDigitalReadPinTurnOn;
@property (unsafe_unretained, nonatomic) BOOL isAnalogSendPinTurnedOn;
@property (unsafe_unretained, nonatomic) BOOL isAnalogReadPinTurnedOn;
@property (unsafe_unretained, nonatomic) BOOL isServoPinTurnedOn;
@property (strong, nonatomic) CBService *cachedService;
@property (strong, nonatomic) CBCharacteristic *cachedCharacteristic;
@end


NSString * const kPeripheralErrorConnectionTypeKeyName = @"Type";
NSString * const kErrorObjectKeyName = @"ErrorObject";
NSString * const kServiceDataKeyName = @"kCBAdvDataServiceUUIDs";
NSString * const kDescriptorKeyName = @"Descriptor";
NSString * const kCharacteristicKeyName = @"Characteristic";
NSString * const kRSSIValueKeyName = @"peripheralRSS";
@implementation BLEManagerController

+ (BLEManagerController *)sharedManager{
    static BLEManagerController *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BLEManagerController alloc] init];
    });
    return manager;
}

//Designated Initializer
- (instancetype)init{
    self = [super init];
    if (self) {
        self->_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    return self;
}

#pragma mark - CoreBluetooth Delegate CallBacks

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    //Now that we are connected we need to discover all the services that this peripheral has. This will allow us to query peripheral.services and
    //actually get a value.
    BLELogging(@"Did Connect to peripheral %@ : starting to discover Services", peripheral);
    self.isConnected = YES;
    
    //Setting up to read RSSI
    [self readRSSIFromActivePeripheral];
    [self.activePeripheral discoverServices:nil];
    [self sendMessageToDelegate:@selector(didConnectToPeripheral) withObject:nil];
}

- (void)readRSSIFromActivePeripheral{
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scanTimer:) userInfo:nil repeats:YES];
}

- (void)scanTimer:(NSTimer *)timer{
    [self.activePeripheral readRSSI];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    BLELogging(@"Disconnected from peripheral %@ with error : %@", peripheral, error);
    self.isConnected = NO;
    self.activePeripheral = nil;
    [self sendMessageToDelegate:@selector(didDisconnectFromPeripheral) withObject:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    BLELogging(@"Failed to connect to peripheral : %@ with error : %@", peripheral, error);
    
    [self sendMessageToDelegate:@selector(errorAttemptingToConnectToPeripheral:) withObject:@{kPeripheralErrorConnectionTypeKeyName : @(kCouldNotConnectToPeripheral), kErrorObjectKeyName : error}];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    BLELogging(@"Found peripheral with RSSI %@ : peripheral : %@ advertisment data : %@", RSSI, peripheral, advertisementData);
    NSArray *service = advertisementData[kServiceDataKeyName];
    CBUUID *uuid = service.firstObject;
    if ([uuid isEqual:[CBUUID UUIDWithString:RBL_SERVICE_UUID]]) {
        self.activePeripheral = peripheral;
        [self.centralManager stopScan];
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals{
    BLELogging(@"Discovered Connected Peripherals %@", peripherals);
    [self sendMessageToDelegate:@selector(didCollectAllNearbyPeripherals:) withObject:peripherals];
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals{
    [self sendMessageToDelegate:@selector(didFindPeripherals) withObject:nil];
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict{
    [self sendMessageToDelegate:@selector(bluetoothStateChanged:) withObject:@(central.state)];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    [self sendMessageToDelegate:@selector(bluetoothStateChanged:) withObject:@(central.state)];
}

#pragma mark - Peripheral Delegate Callback 

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    BLELogging(@"Discovered service %@ : with Error %@", peripheral, error);
    self.cachedService = [self findServiceWithUUID:[CBUUID UUIDWithString:RBL_SERVICE_UUID]];
    [self.activePeripheral discoverCharacteristics:Nil forService:self.cachedService];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error{
    //Leaving this blank for right now.
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    BLELogging(@"Did Discover Characteristics For Service : %@ error : %@", service, error);
    self.cachedCharacteristic = [self findCharacteristicWithUUID:[CBUUID UUIDWithString:RBL_CHAR_RX_UUID] withService:self.cachedService];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //Leaving this blank for right now.
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    BLELogging(@"Read Data for characteristic  %@ : with Error %@", characteristic, error);
    [self sendMessageToDelegate:@selector(didReadValue:) withObject:@{kCharacteristicKeyName : characteristic , kErrorObjectKeyName : error}];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    BLELogging(@"Read Data for Descriptor %@ : with error %@", descriptor, error);
    [self sendMessageToDelegate:@selector(didReadValueForDescriptor:) withObject:@{kErrorObjectKeyName : error, kDescriptorKeyName : descriptor}];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    BLELogging(@"Wrote data for characteristic %@ : with error %@", characteristic, error);
    [self sendMessageToDelegate:@selector(didWriteDataToDeviceForCharacteristic:) withObject:@{kCharacteristicKeyName : characteristic, kErrorObjectKeyName : error}];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    BLELogging(@"Wrote date for descriptor %@ : with error %@", descriptor, error);
    [self sendMessageToDelegate:@selector(didWriteValueForBLEDescriptor:) withObject:@{kDescriptorKeyName : descriptor, kErrorObjectKeyName : error}];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error) {
        [self sendMessageToDelegate:@selector(didRecieveErrorForCharacteristicUpdateNote:) withObject:error];
    }else{
        [self sendMessageToDelegate:@selector(didRecieveCharacteristicUpdateNotification) withObject:nil];
    }
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    //Leaving this blank for the time being.
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    BLELogging(@"Updated RSSI for peripheral %@ : RSSI %@ : and Error %@", peripheral, peripheral.RSSI, error);
    
    [self sendMessageToDelegate:@selector(didUpdateTheRSSIForPeripheral:) withObject:@{@"peripheralRSS" : peripheral.RSSI}];
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices{
    //Leaving this blank for the time being.
}

#pragma mark - Initial BLE Connection

- (void)findDevices{
    //Scans for peripherals with the CBUUID of the RBL BLE Sheild.  Once a peripheral is located the Central Manager delegate method
    //centralManager:didDisconnectPeripheral:error: is called. Inside of this method the peripheral is cached for later use and then
    //an attempt to connect to the peripheral is made.
    
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:RBL_SERVICE_UUID]] options:nil];
}

- (void)connectToPeripheral{
    //This should be an automatic call once a peripheral is detected. After a successful connection is made we start the process of detecting services.
    if (self.activePeripheral) {
        self.activePeripheral.delegate = self;
        [self.centralManager connectPeripheral:self.activePeripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey : @(YES), CBConnectPeripheralOptionNotifyOnDisconnectionKey : @(YES), CBConnectPeripheralOptionNotifyOnNotificationKey : @(YES)}];
    }else{
        BLELogging(@"There is no activer peripheral");
        [self sendMessageToDelegate:@selector(errorAttemptingToConnectToPeripheral:) withObject:@{kPeripheralErrorConnectionTypeKeyName : @(kNoPeripheralDiscovered)}];
    }
}

#pragma mark - Data Manipulation 

- (void)writeValue:(NSDictionary *)payload{
    
    //Takes the service UUID and Characteristic that we are already of aware of and sends data to them.  The data is first changed from objects to bytes.
    //Once the data is in bytes its wrapped in an NSData object and passed to the RBL BLE.
    NSData *payloadData = [self createPayloadData:payload];
    
    [self writeValueWithData:payloadData];
}


- (void)writeValueWithData:(NSData *)data{
    if (self.activePeripheral && self.isConnected) {
        
        if (self.cachedCharacteristic) {
            [self.activePeripheral writeValue:data forCharacteristic:self.cachedCharacteristic type:CBCharacteristicWriteWithoutResponse];
        }else{
            BLELogging(@"The cached characteristic is nil");
            
            NSError *error = [[NSError alloc] initWithDomain:@"BLEDomain" code:kNoConfigurationCode userInfo:@{NSLocalizedDescriptionKey : @"There was error finding the configurtion for the BLE Device"}];
            [self sendMessageToDelegate:@selector(didEncounterErrorAttemptingToReadDataFromPeripheral:) withObject:@{kErrorObjectKeyName : error}];
        }
        
    }else{
        BLELogging(@"There is no active peripheral");
        NSError *error = [[NSError alloc] initWithDomain:@"BLEDomain" code:kNoPeripheralCode userInfo:@{NSLocalizedDescriptionKey : @"There was an error attempting to find the connected peripheral."}];
        [self sendMessageToDelegate:@selector(didEncounterErrorAttemptingToReadDataFromPeripheral:) withObject:@{kErrorObjectKeyName : error}];
    }
}

- (NSData *)createPayloadData:(NSDictionary *)attributes{
    //Translates the objects to bytes to be sent to the C code on the arduino. 
    NSNumber *pinType = attributes[kPinTypeKeyValue];
    NSNumber *pinActivationValue = attributes[kPinDataPayload];
    
    UInt8 dat[2] = {pinType.unsignedIntegerValue, pinActivationValue.unsignedIntegerValue};
    NSData *valRet = [NSData dataWithBytes:dat length:2];
    
    return valRet;
}

#pragma mark - Reading Data
- (void)readDataFromBLE{
    if (self.activePeripheral && self.isConnected) {
        if (self.cachedCharacteristic) {
            [self.activePeripheral readValueForCharacteristic:self.cachedCharacteristic];
        }else{
            BLELogging(@"Error reading data from characteristic the cached characteristic is nil");
            NSError *error = [[NSError alloc] initWithDomain:@"BLEDomain" code:kNoConfigurationCode userInfo:@{NSLocalizedDescriptionKey : @"There was error finding the configurtion for the BLE Device"}];
            [self sendMessageToDelegate:@selector(didEncounterErrorAttemptingToReadDataFromPeripheral:) withObject:@{kErrorObjectKeyName : error}];
        }
    }else{
        BLELogging(@"Errro reading data form characteristic the active peripheral is either not connected or nil");
        NSError *error = [[NSError alloc] initWithDomain:@"BLEDomain" code:kNoPeripheralCode userInfo:@{NSLocalizedDescriptionKey : @"There was an error attemtping to find the connected peripheral."}];
        [self sendMessageToDelegate:@selector(didEncounterErrorAttemptingToReadDataFromPeripheral:) withObject:@{kErrorObjectKeyName : error}];
    }
}
#pragma mark - Utilities

- (CBService *)findServiceWithUUID:(CBUUID *)UUID{
    NSArray *services = self.activePeripheral.services;
    CBService *theService = nil;
    for (CBService *service in services) {
        if ([service.UUID isEqual:UUID]) {
            theService = service;
        }
    }
    return theService;
}

- (CBCharacteristic *)findCharacteristicWithUUID:(CBUUID *)charUUID withService:(CBService *)service{
    CBCharacteristic *aChar = nil;
    NSArray *characteristics = service.characteristics;
    
    for (CBCharacteristic *car in characteristics) {
        if ([car.UUID isEqual:charUUID]) {
            aChar = car;
        }
    }
    
    return aChar;
}

- (void)sendMessageToDelegate:(SEL)message withObject:(id)object{
    if ([self.delegate respondsToSelector:message]) {
        if (object) {
            [self.delegate performSelector:message withObject:object];
        }else{
            [self.delegate performSelector:message];
        }
    }
}

- (NSString *)stateTranslator:(CBCentralManagerState)state{
    NSString *valRet = nil;
    
    switch (state) {
        case CBCentralManagerStateUnknown:{
            valRet = @"Bluetooth State is Uknown";
        }break;
            
        case CBCentralManagerStateResetting:{
            valRet = @"Bluetooth is resetting";
        }break;
            
        case CBCentralManagerStateUnsupported:{
            valRet = @"Bluetooth is unsupported on this device";
        }break;
            
        case CBCentralManagerStateUnauthorized:{
            valRet = @"Bluetooth interaction is unsupported";
        }break;
            
        case CBCentralManagerStatePoweredOff:{
            valRet = @"Bluetooth is powered off";
        }break;
            
        case CBCentralManagerStatePoweredOn:{
            valRet = @"Bluetooh is powered on";
        }break;
            
        default:{
            valRet = @"Bluetooth state is unknown";
        }break;
    }
    
    return valRet;
}
@end
