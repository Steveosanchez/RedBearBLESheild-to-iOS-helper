//
//  BLEManagerController.h
//  BLE Test
//
//  Created by Steve_Sanchez on 1/9/14.
//  Copyright (c) 2014 Apargo LLC. All rights reserved.
//


//As its name implies this class helps manage all of the bluetooth interactions.  It pases relevant delgate calls back to the UI.
//It creates a Cingelton that manages all Bluetooth interactions for the life of the app.
//A couple of things to keep in mind when sending payloads to this class for the BLE Arduino Sheild from RBL:
//The companion code for this project is expecting an array. Of values with the first value determining which type of Operation is to be performed.
//The second array value has the data packet to be sent.  The values and pin type names are included in BLEConstants.h Keeping in mind that for analog
//and servo pin types the values have a min and max. For Analog its 0 - 255 and for servo its 0 - 180.

#import <Foundation/Foundation.h>

@import CoreBluetooth;

@protocol BLEManagerControllerDelegate;

@interface BLEManagerController : NSObject


@property (weak, nonatomic) id<BLEManagerControllerDelegate> delegate;
+ (BLEManagerController *)sharedManager; //Cingleton Creation
- (void)findDevices; //Finds all nearby peripherals that are from RBL.
- (void)connectToPeripheral;
- (void)writeValue:(NSDictionary *)payload; //Writes data to the Arduino by translating objects into bytes.
- (NSString *)stateTranslator:(CBCentralManagerState)state; //Allows interested objects to translate BLE state into appropriate text.
- (void)readDataFromBLE; //This will read data and pass it back via a delegate method. 
@end


@protocol BLEManagerControllerDelegate <NSObject>

- (void)bluetoothIsTurnedOffError;
- (void)errorAttemptingToConnectToPeripheral:(NSDictionary *)type;
- (void)didConnectToPeripheral;
- (void)didDisconnectFromPeripheral;
- (void)didWriteDataToDeviceForCharacteristic:(NSDictionary *)attributes;
- (void)didUpdateTheRSSIForPeripheral:(NSDictionary *)update;
- (void)didFindPeripherals;
- (void)didEncounterErrorAttemptingToReadDataFromPeripheral:(NSDictionary *)response;
- (void)didReadValue:(NSDictionary *)response;
- (void)didReadValueForDescriptor:(NSDictionary *)response;
@optional
- (void)didRecieveErrorForCharacteristicUpdateNote:(NSError *)error;
- (void)didRecieveCharacteristicUpdateNotification;
- (void)didWriteValueForBLEDescriptor:(NSDictionary *)response;
- (void)bluetoothStateChanged:(CBCentralManagerState)state;
- (void)didCollectAllNearbyPeripherals:(NSArray *)peripherals;
@end


extern NSString * const kDescriptorKeyName;
extern NSString * const kCharacteristicKeyName;
extern NSString * const kPeripheralErrorConnectionTypeKeyName;
extern NSString * const kErrorObjectKeyName;
extern NSString * const kRSSIValueKeyName;

typedef enum DataReadingErrorCodes : NSInteger{
    kNoPeripheralCode = 1101,
    kNoConfigurationCode = 1102
}DataReadingErrorTypes;
