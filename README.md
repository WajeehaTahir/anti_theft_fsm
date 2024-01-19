# Anti-Theft System

## Description

The system is designed to automatically arm itself when the ignition is turned off, the driver exits the car, and a specified arming delay (T_ARM_DELAY) has passed. Additionally, if there is a passenger, the system arms itself after both the driver's and passenger's doors are closed, with the countdown delay (T_PASSENGER_DELAY) initiated. The system includes a countdown mechanism triggered by opening the driver's door, and if the ignition is not turned on within the countdown interval (T_DRIVER_DELAY), the alarm is activated.

In addition to the standard alarm functionality, a secret deterrent has been implemented to control the power to the fuel pump. Power to the fuel pump is cut off when the ignition is off, and it is restored only when the ignition is turned on, and the driver presses both a hidden switch and the brake pedal simultaneously.

The system incorporates a status indicator LED on the dashboard, which blinks with a two-second period when the system is armed. The LED is constantly illuminated when the system is in the countdown waiting for the ignition to turn on or when the siren (another LED) is activated. The LED is turned off when the system is disarmed.


## Device Configuration

The following ports are used for various sensors and actuators:

- **Hidden Switch:** `btn[1]` (Up Button)
- **Brake Depressed Switch:** `btn[3]` (Down Button)
- **Driver Door Switch:** `btn[2]` (Left Button)
- **Passenger Door Switch:** `btn[4]` (Right Button)
- **Ignition Switch:** `sw[6]`
- **Time Parameter Selector:** `sw[5:4]`
- **Time Value:** `sw[3:0]`
- **Reprogram Button:** `btn[0]` (Center Button)
- **Status Light:** `led[0]`
- **Fuel Pump Power:** `led[1]`
- **Siren Output:** `led[2]`
- **System Reset:** `sw[7]`


## Default Timing Parameters

| Interval Name             | Symbol           | Parameter Number | Default Time (sec) | Time Value |
| ------------------------- | ----------------- | ----------------- | ------------------- | ---------- |
| Arming delay              | T_ARM_DELAY       | 00                | 6                   | 0110       |
| Countdown, driver's door  | T_DRIVER_DELAY    | 01                | 8                   | 1000       |
| Countdown, passenger door | T_PASSENGER_DELAY | 10                | 15                  | 1111       |
| Siren ON time             | T_ALARM_ON         | 11                | 10                  | 1010       |

The system timings are based on the specified parameters, and these can be reprogrammed using the Time_Parameter_Selector, Time_Value, and Reprogram signals.


## Lab Details

This project corresponds to Lab 4 of MIT's 6.111 Digital Systems Laboratory. For detailed lab instructions and additional information, please refer to the [Lab 4 Documentation](https://web.mit.edu/6.111/volume2/www/f2019/handouts/labs/lab4_19/index.html).

*Documented by ChatGPT*
