//
//  BluetoothInterface.swift
//  Rc-Car-Controller
//
//  Created by Justin Elias on 3/1/19.
//  Adapted from https://www.appcoda.com/core-bluetooth/
//  Copyright © 2019 Justin Elias. All rights reserved.
//

import CoreBluetooth
import UIKit

let BLE_Service_CBUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
let BLE_Report_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

class BluetoothInterface: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var peripheralCar: CBPeripheral?
    var rightControlCharacteristic: CBCharacteristic?
    var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // STEP 1: create a concurrent background queue for the central
    let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
    
    // STEP 2: create a central to scan for, connect to,
    // manage, and collect data from peripherals
    
    func setCentralQueue() {
        self.centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    // STEP 3.1: this method is called based on
    // the device's Bluetooth state; we can ONLY
    // scan for peripherals if Bluetooth is .poweredOn
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
            
        case .unknown:
            print("Bluetooth status is UNKNOWN")
        case .resetting:
            print("Bluetooth status is RESETTING")
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            
            // STEP 3.2: scan for peripherals that we're interested in
            centralManager?.scanForPeripherals(withServices: [BLE_Service_CBUUID])
            
        } // END switch
    } // END func centralManagerDidUpdateState
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print(peripheral.name!)
        decodePeripheralState(peripheralState: peripheral.state)
        // STEP 4.2: MUST store a reference to the peripheral in
        // class instance variable
        peripheralCar = peripheral
        // STEP 4.3: since HeartRateMonitorViewController
        // adopts the CBPeripheralDelegate protocol,
        // the peripheralHeartRateMonitor must set its
        // delegate property to HeartRateMonitorViewController
        // (self)
        peripheralCar?.delegate = self
        
        // STEP 5: stop scanning to preserve battery life;
        // re-scan if disconnected
        centralManager?.stopScan()
        
        // STEP 6: connect to the discovered peripheral of interest
        centralManager?.connect(peripheralCar!)
        
    } // END func centralManager(... didDiscover peripheral
    
    // STEP 7: "Invoked when a connection is successfully created with a peripheral."
    // we can only move forwards when we know the connection
    // to the peripheral succeeded
    func centralManager(_ central: CBCentralManager, didConnect peripheralCar: CBPeripheral) {
        
        DispatchQueue.main.async { () -> Void in
            
            self.scene?.setDevice(value: peripheralCar.name!)
        }
        // STEP 8: look for services of interest on peripheral
        peripheralCar.discoverServices([BLE_Service_CBUUID])
        
    } // END func centralManager(... didConnect peripheral
    
    // STEP 15: when a peripheral disconnects, take
    // use-case-appropriate action
    private func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        DispatchQueue.main.async { () -> Void in
            self.scene?.setDevice(value: "-----")
        }
        
        
        // STEP 16: in this use-case, start scanning
        // for the same peripheral or another, as long
        // as they're HRMs, to come back online
        centralManager?.scanForPeripherals(withServices: [BLE_Service_CBUUID])
        
    } // END func centralManager(... didDisconnectPeripheral peripheral
    
    // MARK: - CBPeripheralDelegate methods
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            
            if service.uuid == BLE_Service_CBUUID {
                
                print("Service: \(service)")
                
                // STEP 9: look for characteristics of interest
                // within services of interest
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
        }
        
    } // END func peripheral(... didDiscoverServices
    
    // STEP 10: confirm we've discovered characteristics
    // of interest within services of interest
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            print(characteristic)
            
            if characteristic.uuid == BLE_Report_Characteristic_CBUUID {
                rightControlCharacteristic = characteristic
            }
            
        } // End for
    } // END func peripheral(... didDiscoverCharacteristicsFor service
    
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        
        switch peripheralState {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
        }
        
    } // END func decodePeripheralState(peripheralState
    
    func peripheralWrite(value: UInt8){
        
        let bytes: [UInt8] = [value]
        let data = Data(bytes: bytes)
        print(value, data)
        if peripheralCar != nil {
            peripheralCar!.writeValue(data, for: self.rightControlCharacteristic!, type:
                CBCharacteristicWriteType.withResponse)
        }
    }
    
}
