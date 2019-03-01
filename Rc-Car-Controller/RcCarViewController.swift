//
//  ViewController.swift
//  test_ble
//
//  Created by Justin Elias on 2/26/19.
//  Copyright © 2019 Justin Elias. All rights reserved.
//

import UIKit
import SpriteKit


//let BLE_L2CAP_CHANNEL_CBUUID = CBUUID(string: "0x001F")

class RcCarViewController: UIViewController {
    
    
    var scene: GameScene?
    var ble: BluetoothInterface?
    
    override func viewDidLoad(){
        
        super.viewDidLoad()
        
        scene = GameScene(size: self.view.bounds.size)
        scene!.backgroundColor = .white
        
        if let skView = self.view as? SKView {
            skView.showsFPS = false
            skView.showsNodeCount = true
            skView.ignoresSiblingOrder = true
            skView.presentScene(scene)
        }
        
        ble = BluetoothInterface(scene: scene!)
        ble?.setCentralQueue()
        scene?.setPeripheral(value: ble)

            
    }
    
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
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
}

