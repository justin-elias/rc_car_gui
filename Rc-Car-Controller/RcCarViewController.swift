//
//  RcCarViewController.swift
//
//
//  Created by Justin Elias on 2/26/19.
//  Copyright © 2019 Justin Elias. All rights reserved.
//

import UIKit
import SpriteKit

/**
* Primary View Controller which launches the bluetooth discovery process, and determines if a gamepad is present,
* or if the virtual controller should be initially used.
**/
class RcCarViewController: UIViewController {


    var scene: GamepadScene?
    var ble: BluetoothInterface?
    override func viewDidLoad() {

        super.viewDidLoad()

        //initialize gamepad scene. No virtual joysticks showing
        scene = GamepadScene(size: self.view.bounds.size)
        scene!.backgroundColor = .white

        // start the scene that is shown on the screen of the phone
        if let skView = self.view as? SKView {
            skView.showsFPS = false
            skView.showsNodeCount = false
            skView.ignoresSiblingOrder = true
            skView.presentScene(scene)
        }

        // initialize bluetooth functions
        ble = BluetoothInterface(scene: scene!)

        // start bluetooth scan
        self.scanBLE()

    }

    /**
    * Function which looks for RC car server
    **/
    func scanBLE(){
        if ble != nil {
            ble?.setCentralQueue()
            scene?.setPeripheral(value: ble)
        }
    }

    // Does scene to autorotate as phone rotates
    override var shouldAutorotate : Bool {
        return true
    }
    
    // Force landscape mode
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask  {
        return UIDevice.current.userInterfaceIdiom == .phone ? .landscape: .landscape
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Does phone status bar show. i.e. reception status, time etc
    override var prefersStatusBarHidden : Bool {
        return false
    }
}

