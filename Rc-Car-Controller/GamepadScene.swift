//
// Created by Justin Elias on 2019-04-13.
// Copyright (c) 2019 Justin Elias. All rights reserved.
//

import SpriteKit
import GameController

class GamepadScene: SKScene{
    var controllerConnected = false
    var gamepad: GCExtendedGamepad?
    let deviceNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    let gearLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
    var appleNode: SKSpriteNode?
    var peripheral: BluetoothInterface?

    // Variables to identify if right and left tracks are currently moving
    var rightMovingFwd = false
    var leftMovingFwd = false
    var rightMovingRvs = false
    var leftMovingRvs = false

    // Variables for reading gamepad input
    var leftThumbstickUp: GCExtendedGamepad?
    var leftThumbstickDown: GCExtendedGamepad?
    var rightThumbstickUp: GCExtendedGamepad?
    var rightThumbstickDown: GCExtendedGamepad?

    // Variables for gears
    let minGear = 1
    var gear: Int?
    let maxGear = 5

    // Initial setup of the scene
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        backgroundColor = UIColor.white
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        gear = self.minGear
        self.changeGears(gearIn: self.minGear)
        setUpControllerObservers()
        connectControllers()

//        let bluetoothSwitch = UISwitch(frame:CGRect(x: 10, y: 10, width: 0, height: 0))
//        bluetoothSwitch.isOn = false
//        bluetoothSwitch.setOn(false, animated: true)
//        self.view!.addSubview(bluetoothSwitch)
        self.setDevice(value: "-----")

        self.setGearLabel(value: String(gear!))

        view.isMultipleTouchEnabled = true
    }

    /**
    * Set of functions which take the input of the gamepad and call the appropriate bluetooth write function
    **/
    func gamepadJoyStick() {
        let leftThumbstickUp = self.gamepad!.leftThumbstick.up
        let leftThumbstickDown = self.gamepad!.leftThumbstick.down
        let rightThumbstickDown = self.gamepad!.rightThumbstick.down
        let rightThumbstickUp = self.gamepad!.rightThumbstick.up
        let rightTrigger = self.gamepad!.rightTrigger
        let leftTrigger = self.gamepad!.leftTrigger

        // Actions based on state of right Thumbstick
        if rightThumbstickUp.isPressed && self.rightMovingFwd == false{
            self.rightForward()
        }else if rightThumbstickDown.isPressed && self.rightMovingRvs == false{
            self.rightReverse()
        }else if !rightThumbstickUp.isPressed && !rightThumbstickDown.isPressed{
            if self.rightMovingRvs || self.rightMovingFwd {
                self.rightStop()
            }
        }

        //Actions based on state of left Thumbstick
        if leftThumbstickDown.isPressed && self.leftMovingRvs == false{
            self.leftReverse()
        } else if leftThumbstickUp.isPressed && self.leftMovingFwd == false{
            self.leftForward()
        }else if !leftThumbstickUp.isPressed && !leftThumbstickDown.isPressed{
            if self.leftMovingRvs || self.leftMovingFwd {
                self.leftStop()
            }
        }

        // Increase gear if Left Trigger Pulled
        if leftTrigger.isPressed {
            var reset = false
            while leftTrigger.isPressed {
                while !reset {
                    if gear! < self.maxGear {
                        gear! += 1
                        self.changeGears(gearIn: gear!)
                        reset = true
                    }else {
                        reset = true
                    }
                    print(gear!)
                }
            }
        }

        // Decrease gear if Right Trigger Pulled
        if rightTrigger.isPressed {
            var reset = false
            while rightTrigger.isPressed {
                while !reset {
                    if gear! > self.minGear {
                        gear! -= 1
                        self.changeGears(gearIn: gear!)
                        reset = true
                    }else{
                        reset = true
                    }
                }
            }
        }
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

    func rightStop() {
        self.peripheral?.peripheralWrite(value: 0x30, track: "right")
        self.rightMovingFwd = false
        self.rightMovingRvs = false
    }

    func rightReverse() {
        self.rightMovingRvs = true
        self.peripheral?.peripheralWrite(value: 0x32, track: "right")
    }

    func rightForward() {
        self.rightMovingFwd = true
        self.peripheral?.peripheralWrite(value: 0x31, track: "right")
    }

    func changeGears(gearIn: Int){
        var nextGear: UInt8?
        switch gearIn{
        case 1:
            nextGear = 0x31
        case 2:
            nextGear = 0x32
        case 3:
            nextGear = 0x33
        case 4:
            nextGear = 0x34
        case 5:
            nextGear = 0x35
        default:
            nextGear = 0x31
        }
        self.peripheral?.peripheralWrite(value: nextGear!, track: "gear")
        self.setGearLabel(value: String(gearIn))
    }

    // Checks if controller has been connected before frame refresh, if Controller was connected, switches to GamepadScene
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        if self.controllerConnected {
            self.gamepadJoyStick()
        }else {
            let scene = JoyStickScene(size: self.view!.bounds.size)
            scene.setPeripheral(value: self.peripheral)
            self.changeGears(gearIn: 1)
            self.gearLabel.isHidden = true
            self.view?.presentScene(scene, transition: SKTransition.moveIn(with: SKTransitionDirection.down, duration: 1))

        }
    }

    func setPeripheral(value: BluetoothInterface?){

        self.peripheral = value
    }

    func setUpControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(GamepadScene.connectControllers), name: NSNotification.Name.GCControllerDidConnect, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(GamepadScene.controllerDisconnected), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
    }

    // Check if controller is connected
    @objc func connectControllers() {

        print(GCController.controllers().count)
        if !GCController.controllers().isEmpty {
            print("Controller connected")
            self.controllerConnected = true
            print(self.controllerConnected)
            gamepad = GCController.controllers()[0].extendedGamepad!
        }

    }

    // Check if controller is disconnected
    @objc func controllerDisconnected() {

        print("Controller disconnected")

        self.controllerConnected = false
    }

    // Set images and text on screen
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

    // Set text of gear indicator
    func setGearLabel(value: String?){
        self.gearLabel.adjustsFontSizeToFitWidth = false
        self.gearLabel.center = CGPoint(x: self.frame.midX, y: self.frame.maxY - 220)
        self.gearLabel.textAlignment = .center
        self.gearLabel.text = value
        self.gearLabel.textColor = .red
        self.gearLabel.font = UIFont.systemFont(ofSize: 40.0)
        self.view!.addSubview(self.gearLabel)
        self.gearLabel.isHidden = false

        let gearNum = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 90))
        gearNum.center = CGPoint(x: self.frame.midX, y: self.frame.maxY - 180 )
        gearNum.textAlignment = .center
        gearNum.text = "Gear"
        self.view!.addSubview(gearNum)
    }
}


