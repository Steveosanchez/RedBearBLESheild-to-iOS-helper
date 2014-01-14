//
//  BLEConstants.h
//  BLE Test
//
//  Created by Steve_Sanchez on 1/9/14.
//  Copyright (c) 2014 Apargo LLC. All rights reserved.
//

#ifndef BLE_Test_BLEConstants_h
#define BLE_Test_BLEConstants_h

#define RBL_SERVICE_UUID                         @"713D0000-503E-4C75-BA94-3148F18D941E"
#define RBL_CHAR_TX_UUID                         @"713D0002-503E-4C75-BA94-3148F18D941E"
#define RBL_CHAR_RX_UUID                         @"713D0003-503E-4C75-BA94-3148F18D941E"

#define RBL_BLE_FRAMEWORK_VER                    0x0200
#define BLELoggerActive 1

typedef enum PeripheralErrorTypes : NSInteger{
    kNoPeripheralDiscovered = 0,
    kCouldNotConnectToPeripheral = 1
}PeripheralErrorTypes;

typedef enum PeripheralPinTypes : NSInteger{
    kPinTypeDigital = 1,
    kPinTypeAnalog = 2,
    kPinTypeServo = 3,
    kPinTypeAnalogReadTurnOnOFF = 160,
    kPinTypeReadAnalog = 11,
    kPinTypeDigitalReadInput = 10
}PeripheralPinTypes;

#define kOnValue 1
#define kOffValue 0

#define kPinTypeKeyValue @"PinTypeKey"
#define kPinDataPayload @"ActivationValue"
#define kPinAnalogPayload @"AnalogPayload"

#define BLELogging(fmt, ...) \
do { \
if(BLELoggerActive) \
NSLog(@"%s:%d (%s) BLELogging log: --- " fmt, __FILE__, __LINE__, __func__, ## __VA_ARGS__); \
} while(0)

#endif
