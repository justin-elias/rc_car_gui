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
    var moving = false
    
    
    // lazy marks variable as not being initialized until first time it is used. Needed to make sure that frame was 
    // available to set the y position
    lazy var yPos = CGFloat(frame.midY)
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
    
    
    let leftAnalogStick = 🕹(diameter: 110) // from Emoji
    let rightAnalogStick = AnalogJoystick(diameter: 100) // from Class
    
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        backgroundColor = UIColor.white
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        leftAnalogStick.position = CGPoint(x: leftAnalogStick.radius + 15, y: leftAnalogStick.radius + 15)
        addChild(leftAnalogStick)
        rightAnalogStick.position = CGPoint(x: self.frame.maxX - rightAnalogStick.radius - 15, y:rightAnalogStick.radius + 15)
        addChild(rightAnalogStick)
        
        let bluetoothSwitch = UISwitch(frame:CGRect(x: 10, y: 10, width: 0, height: 0))
        bluetoothSwitch.isOn = false
        bluetoothSwitch.setOn(false, animated: true)
        self.view!.addSubview(bluetoothSwitch)
        
        let deviceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        deviceLabel.center = CGPoint(x: self.frame.maxX-45, y: 20)
        deviceLabel.textAlignment = .center
        deviceLabel.text = "Device"
        self.view!.addSubview(deviceLabel)
        
        
        self.setDevice(value: "-----")
        
        
        //MARK: Handlers begin
        
        leftAnalogStick.trackingHandler = { [unowned self] data in
            
            guard let aN = self.appleNode else {
                return
            }

            // starting position will be last known x and last know y coordinates.
            aN.position = CGPoint(x: self.frame.midX, y: aN.position.y + (data.velocity.y * 0.12))
        }

        leftAnalogStick.stopHandler = { [unowned self] in

            guard let aN = self.appleNode else {
                return
            }

            // at stop, resets the turn joystick to mid x coordinate and last known y coordinate.
            // Simulates wheels stop turn when steering in released
            aN.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        }

        
        rightAnalogStick.trackingHandler = { [unowned self] data in
            guard let aN = self.appleNode else {
                return
            }
            aN.position = CGPoint(x: self.frame.midX, y: aN.position.y + (data.velocity.y * 0.12))
            
            let ledOn = self.frame.midY + (self.frame.midY/2)
            if aN.position.y > ledOn && !self.moving {
                self.moving = true
                self.peripheral?.peripheralWrite(value: 0x31)
            }
        }

        rightAnalogStick.stopHandler = { [unowned self] in
            guard let aN = self.appleNode else {
                return
            }
            aN.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            self.peripheral?.peripheralWrite(value: 0x30)
            self.moving = false
        }
        
        //MARK: Handlers end
        joystickStickImageEnabled = true
        joystickSubstrateImageEnabled = true
        
        setRandomStickColor()
        addApple(CGPoint(x: frame.midX, y: frame.midY))

        view.isMultipleTouchEnabled = true
    }
    
    func addApple(_ position: CGPoint) {
        
        guard let appleImage = UIImage(named: "apple") else {
            return
        }
        
        let texture = SKTexture(image: appleImage)
        let apple = SKSpriteNode(texture: texture)
        apple.physicsBody = SKPhysicsBody(texture: texture, size: apple.size)
        apple.physicsBody!.affectedByGravity = false
        apple.position = position
        addChild(apple)
        appleNode = apple
    }
    
    func setRandomStickColor() {
        let randomColor = UIColor.random()
        leftAnalogStick.stick.color = randomColor
        rightAnalogStick.stick.color = randomColor
    }
    
    func setRandomSubstrateColor() {
        let randomColor = UIColor.random()
        leftAnalogStick.substrate.color = randomColor
        rightAnalogStick.substrate.color = randomColor
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func setDevice(value: String?) {
        self.deviceNameLabel.adjustsFontSizeToFitWidth = true
        self.deviceNameLabel.center = CGPoint(x: self.frame.maxX-50, y: 40)
        self.deviceNameLabel.textAlignment = .center
        self.deviceNameLabel.text = value
        self.view!.addSubview(self.deviceNameLabel)
    }
    
    func setPeripheral(value: BluetoothInterface?){
        
        self.peripheral = value
    }
    
}

extension UIColor {
    
    static func random() -> UIColor {
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
    }
}
