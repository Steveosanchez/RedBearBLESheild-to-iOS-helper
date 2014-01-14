//
//  APGViewController.m
//  BLE Test
//
//  Created by Steve_Sanchez on 1/9/14.
//  Copyright (c) 2014 Apargo LLC. All rights reserved.
//

#import "APGViewController.h"
#import "BLEManagerController.h"
#import "BLEConstants.h"

@interface APGViewController ()<BLEManagerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *aButton;
@property (strong,nonatomic) BLEManagerController *controller;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) NSNumber *sendingValue;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendValue;

@end

@implementation APGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.controller = [BLEManagerController sharedManager];
    self.controller.delegate = self;
    [self.controller findDevices];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)bluetoothIsTurnedOffError{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Turn BLE On" message:@"You need to turn on your BLE device" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)didConnectToPeripheral{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected" message:@"You have connected to the BLE" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)errorAttemptingToConnectToPeripheral:(NSDictionary *)type{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was an error connecting the peripheral %@", type[kErrorObjectKeyName]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)didDisconnectFromPeripheral{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnect" message:@"Did disconnect from BLE" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)didWriteDataToDeviceForCharacteristic:(NSDictionary *)attributes{
    self.statusLabel.text = @"Did write data to the device";
}

- (void)didUpdateTheRSSIForPeripheral:(NSDictionary *)update{
    self.distanceLabel.text = [NSString stringWithFormat:@"Distance : %@, Error %@",update[kRSSIValueKeyName], update[kErrorObjectKeyName]];
}

- (void)didFindPeripherals{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Found" message:@"Found peripherals" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
- (IBAction)iveBeenHit:(id)sender {
    [self.controller connectToPeripheral];
}
- (IBAction)goAndSend:(id)sender {
    if (self.sendingValue.integerValue == kOffValue) {
        self.sendingValue = @(kOnValue);
    }else{
        self.sendingValue = @(kOffValue);
    }
    [self.controller writeValue:@{kPinTypeKeyValue : @(kPinTypeDigital), kPinDataPayload : self.sendingValue}];
}

@end
