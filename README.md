RedBearBLESheild-to-iOS-helper
==============================

A project to connect iOS to Red Bear Labs BLE Arduino Shield this project has two dependencies

-You must have the BLE Arduino Shield from Red bear Labs

-You must download the library from Red Bear Labs. That allows the controls of the Arduino Shield.

This is a primer for running a project that sends data to a BLE device. It includes a stupidly basic UI for operation.  Its primary purpose is to show the setup and operation of Apple's CoreBluetooth Framework. I hope it helps with your hacks as well.  

###Logging 
This app comes with a built in logger for most major BLE functions.  To turn it off navigate to BLEConstants.h file and change the value of BLELoggerActive to 0 
