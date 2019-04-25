//
//  JoystickScene.swift
//  Virtual joystick view scene. If active, virtual thumbsticks are shown and usable on the screen
//
//  Created by Justin Elias on 3/1/19.
//  Adapted from Dmitriy Mitrophanskiy https://github.com/MitrophD/Swift-SpriteKit-Analog-Stick
//  Copyright © 2019 Justin Elias. All rights reserved.//
import SpriteKit
import GameController


class JoyStickScene: SKScene {
    let deviceNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    var peripheral: BluetoothInterface?
    var rightMovingFwd = false                 // Identify if right and left tracks are currently moving
    var leftMovingFwd = false
    var rightMovingRvs = false
    var leftMovingRvs = false
    var controllerConnected = false

    // lazy marks variable as not being initialized until first time it is used. Needed to make sure that frame was 
    // available to set the y position
    lazy var rightPos = CGFloat(frame.midY)
    lazy var leftPos = CGFloat(frame.midY)

    // Variables to track the input of the virtual thumbsticks
    var rightStick: CGFloat?
    var leftStick: CGFloat?


    // Determine if a gamepad controller has been connected
    @objc func connectControllers() {

        print(GCController.controllers().count)
        if !GCController.controllers().isEmpty {
            print("Controller connected")
            self.controllerConnected = true

        }

    }

    // Determine if a gamepad controller has been disconnected
    @objc func controllerDisconnected() {

        print("Controller disconnected")

        self.controllerConnected = false
    }

    // Image used for joystick
    var joystickStickImageEnabled = true {
        didSet {
            let image = joystickStickImageEnabled ? UIImage(named: "jStick") : nil
            leftAnalogStick.stick.image = image
            rightAnalogStick.stick.image = image
        }
    }

    // Image used for joystick background
    var joystickSubstrateImageEnabled = true {
        didSet {
            let image = joystickSubstrateImageEnabled ? UIImage(named: "jSubstrate") : nil
            leftAnalogStick.substrate.image = image
            rightAnalogStick.substrate.image = image
        }
        
    }
    
    // Set diameter of joystick
    let leftAnalogStick = AnalogJoystick(diameter: 130)
    let rightAnalogStick = AnalogJoystick(diameter: 130)
    
    
    // Initial setup of the scene
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        backgroundColor = UIColor.white

        setUpControllerObservers()
        connectControllers()
        

        self.setDevice(value: "-----")
        self.virtualJoyStick()
        view.isMultipleTouchEnabled = true
    }

    /**
    * Set of functions which control the input written to the bluetooth peripheral
    * written values are hexdecimal translation of ASCII characters. The Rc Car is set to only read these specific characters
    **/
    func leftStop() {
        self.peripheral?.peripheralWrite(value: 0x30, track: "left")
        self.leftMovingFwd = false
        self.leftMovingRvs = false
    }

    func leftForward() {
        self.leftMovingFwd = true
        self.peripheral?.peripheralWrite(value: 0x31, track: "left")
    }

    func leftReverse() {
        self.leftMovingRvs = true
        self.peripheral?.peripheralWrite(value: 0x32, track: "left")
    }

    private func rightStop() {
        self.peripheral?.peripheralWrite(value: 0x30, track: "right")
        self.rightMovingFwd = false
        self.rightMovingRvs = false
    }

    func rightReverse() {
        self.rightMovingFwd = true
        self.peripheral?.peripheralWrite(value: 0x31, track: "right")
    }

    func rightForward() {
        self.rightMovingFwd = true
        self.peripheral?.peripheralWrite(value: 0x31, track: "right")
    }

    /**
    * Set of functions which take the input of the virtual joysticks and call the appropriate bluetooth write function
    **/
    func virtualJoyStick() {
        leftAnalogStick.position = CGPoint(x: leftAnalogStick.radius + 100, y: leftAnalogStick.radius + 100)
        addChild(leftAnalogStick)
        rightAnalogStick.position = CGPoint(x: self.frame.maxX - rightAnalogStick.radius - 100, y:rightAnalogStick.radius + 100)
        addChild(rightAnalogStick)

        // Create deadzone so that a joystick has to move past the halfway point between up and down before a movement command is sent
        let moveTrackFwd = self.frame.midY + (self.frame.midY/2)
        let moveTrackRvs = self.frame.midY - (self.frame.midY/2)

        // Read input of Left virtual joystick. If deadzone is past, send movement signal
        leftAnalogStick.trackingHandler = { [unowned self] data in
            self.leftPos = CGFloat(self.leftPos + (data.velocity.y * 0.12))

            // Uses a boolean variable to determine if the Rc car is already moving in specified direction. If already moving, no signal sent
            // Required to keep send queue from overflowing
            if self.leftPos > moveTrackFwd && !self.leftMovingFwd {
                self.leftMovingFwd = true
                self.peripheral?.peripheralWrite(value: 0x31, track: "left")
            }
            if self.leftPos < moveTrackRvs && !self.leftMovingRvs {
                self.leftMovingRvs = true
                self.peripheral?.peripheralWrite(value: 0x32, track: "left")
            }
        }

        // Read when Left joystick is released. Send stop signal and reset all position variables
        leftAnalogStick.stopHandler = { [unowned self] in
            self.leftPos = self.frame.midY
            self.peripheral?.peripheralWrite(value: 0x30, track: "left")
            self.leftMovingFwd = false
            self.leftMovingRvs = false
        }

        // Read input of Right virtual joystick. If deadzone is past, send movement signal
        rightAnalogStick.trackingHandler = { [unowned self] data in

            self.rightPos = CGFloat(self.rightPos + (data.velocity.y * 0.12))

            // Uses a boolean variable to determine if the Rc car is already moving in specified direction. If already moving, no signal sent
            // Required to keep send queue from overflowing
            if self.rightPos > moveTrackFwd && !self.rightMovingFwd {
                self.rightMovingFwd = true
                self.peripheral?.peripheralWrite(value: 0x31, track: "right")
            }
            //if aN.position.y < moveTrackRvs && !self.rightMovingRvs {
            if self.rightPos < moveTrackRvs && !self.rightMovingRvs {
                self.rightMovingRvs = true
                self.peripheral?.peripheralWrite(value: 0x32, track: "right")
            }
        }

        // Read when Right joystick is released. Send stop signal
        rightAnalogStick.stopHandler = { [unowned self] in
            self.rightPos = self.frame.midY
            self.peripheral?.peripheralWrite(value: 0x30, track: "right")
            self.rightMovingFwd = false
            self.rightMovingRvs = false
        }


        //MARK: Handlers end
        joystickStickImageEnabled = true
        joystickSubstrateImageEnabled = true
    }


    // Checks if controller has been connected before frame refresh, if Controller was connected, switches to GamepadScene
    override func update(_ currentTime: TimeInterval) {
            /* Called before each frame is rendered */
        if self.controllerConnected {
            let scene = GamepadScene(size: self.view!.bounds.size)
            scene.setPeripheral(value: self.peripheral)
            self.view?.presentScene(scene, transition: SKTransition.moveIn(with: SKTransitionDirection.down, duration: 1))
        }

    }

    // Set labels on scene items
    func setDevice(value: String?) {
        self.deviceNameLabel.adjustsFontSizeToFitWidth = true
        self.deviceNameLabel.center = CGPoint(x: self.frame.midX, y: 60)
        self.deviceNameLabel.textAlignment = .center
        self.deviceNameLabel.text = value
        self.view!.addSubview(self.deviceNameLabel)
        
        let deviceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        deviceLabel.center = CGPoint(x: self.frame.midX, y: 40)
        deviceLabel.textAlignment = .center
        deviceLabel.text = "Device"
        self.view!.addSubview(deviceLabel)
    }
    
    func setPeripheral(value: BluetoothInterface?){
        
        self.peripheral = value
    }

    func setUpControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(JoyStickScene.connectControllers), name: NSNotification.Name.GCControllerDidConnect, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(JoyStickScene.controllerDisconnected), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
    }
}
