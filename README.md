# EGEN310 Team F6 Remote Control App
iOS App written for iOS 12.2 which connects to a remote bluetooth capable RC car and offers controls via virtual, on screen joysticks, or bluetooth connected gamepad controller.

## Pertinent Files
These are the files written wholly or modified by Justin Elias
* RcCarViewController.swift
    - Main file which delegates initial actions to control files
* BluetoothInterface.swift
    - Establishes bluetooth connection and provides functions to write to remote bluetooth device
* GamepadScene.swift
    - Sets gamepad scene which shows on iPhone. Connects to gamepad if available, reads inputs and sends write signals to bluetooth device
* JoystickScene.swift
    - Sets virtual joystick scene which shows on iPhone. Reads input from virtual joysticks and sends write signals to bluetooth device.