//
//  GameScene.swift
//
//  Created by Justin Elias on 3/1/19.
//  Adapted from Dmitriy Mitrophanskiy https://github.com/MitrophD/Swift-SpriteKit-Analog-Stick
//  Copyright © 2019 Justin Elias. All rights reserved.//
import SpriteKit


class GameScene: SKScene {
    let deviceNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    var appleNode: SKSpriteNode?
    var peripheral: BluetoothInterface?
    var rightMovingFwd = false                 // Identify if right and left tracks are currently moving
    var leftMovingFwd = false
    var rightMovingRvs = false
    var leftMovingRvs = false

    
    
    // lazy marks variable as not being initialized until first time it is used. Needed to make sure that frame was 
    // available to set the y position
    lazy var rightPos = CGFloat(frame.midY)
    lazy var leftPos = CGFloat(frame.midY)
    var joystickStickImageEnabled = true {
        didSet {
            let image = joystickStickImageEnabled ? UIImage(named: "jStick") : nil
            leftAnalogStick.stick.image = image
            rightAnalogStick.stick.image = image
        }
    }

    var joystickSubstrateImageEnabled = true {
        didSet {
            let image = joystickSubstrateImageEnabled ? UIImage(named: "jSubstrate") : nil
            leftAnalogStick.substrate.image = image
            rightAnalogStick.substrate.image = image
        }
        
    }
    
    
    let leftAnalogStick = AnalogJoystick(diameter: 130)
    let rightAnalogStick = AnalogJoystick(diameter: 130)
    
    
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        backgroundColor = UIColor.white
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        leftAnalogStick.position = CGPoint(x: leftAnalogStick.radius + 100, y: leftAnalogStick.radius + 100)
        addChild(leftAnalogStick)
        rightAnalogStick.position = CGPoint(x: self.frame.maxX - rightAnalogStick.radius - 100, y:rightAnalogStick.radius + 100)
        addChild(rightAnalogStick)
        
        let moveTrackFwd = self.frame.midY + (self.frame.midY/2)
        let moveTrackRvs = self.frame.midY - (self.frame.midY/2)
        
//        let bluetoothSwitch = UISwitch(frame:CGRect(x: 10, y: 10, width: 0, height: 0))
//        bluetoothSwitch.isOn = false
//        bluetoothSwitch.setOn(false, animated: true)
//        self.view!.addSubview(bluetoothSwitch)
        self.setDevice(value: "-----")
        
        
        //MARK: Handlers begin
        
        leftAnalogStick.trackingHandler = { [unowned self] data in
            self.leftPos = CGFloat(self.leftPos + (data.velocity.y * 0.12))
            if self.leftPos > moveTrackFwd && !self.leftMovingFwd {
                self.leftMovingFwd = true
                self.peripheral?.peripheralWrite(value: 0x31, track: "left")
            }
            if self.leftPos < moveTrackRvs && !self.leftMovingRvs {
                self.leftMovingRvs = true
                self.peripheral?.peripheralWrite(value: 0x32, track: "left")
            }
            // starting position will be last known x and last know y coordinates.
            // aN.position = CGPoint(x: self.frame.midX, y: aN.position.y + (data.velocity.y * 0.12))
        }

        leftAnalogStick.stopHandler = { [unowned self] in

            //guard let aN = self.appleNode else {
                //return
    
            //}
            // at stop, resets the turn joystick to mid x coordinate and last known y coordinate.
            // Simulates wheels stop turn when steering in released
            //aN.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            
            self.leftPos = self.frame.midY
            self.peripheral?.peripheralWrite(value: 0x30, track: "left")
            self.leftMovingFwd = false
            self.leftMovingRvs = false
        }

        
        rightAnalogStick.trackingHandler = { [unowned self] data in
            //guard let aN = self.appleNode else {
                //return
            //}
            //aN.position = CGPoint(x: self.frame.midX, y: aN.position.y + (data.velocity.y * 0.12))
            
            //if aN.position.y > moveTrackFwd && !self.rightMovingFwd {
            self.rightPos = CGFloat(self.rightPos + (data.velocity.y * 0.12))
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

        rightAnalogStick.stopHandler = { [unowned self] in
            //guard let aN = self.appleNode else {
                //return
            //}
            //aN.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            self.rightPos = self.frame.midY
            self.peripheral?.peripheralWrite(value: 0x30, track: "right")
            self.rightMovingFwd = false
            self.rightMovingRvs = false
        }
        
        //MARK: Handlers end
        joystickStickImageEnabled = true
        joystickSubstrateImageEnabled = true
        //addApple(CGPoint(x: frame.midX, y: frame.midY))

        view.isMultipleTouchEnabled = true
    }
    
//    func addApple(_ position: CGPoint) {
//
//        guard let appleImage = UIImage(named: "apple") else {
//            return
//        }
//
//        let texture = SKTexture(image: appleImage)
//        let apple = SKSpriteNode(texture: texture)
//        apple.physicsBody = SKPhysicsBody(texture: texture, size: apple.size)
//        apple.physicsBody!.affectedByGravity = false
//        apple.position = position
//        addChild(apple)
//        appleNode = apple
//    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
    
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
    
}
