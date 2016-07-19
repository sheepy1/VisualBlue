//
//  Global.swift
//  VisualBlue
//
//  Created by 杨洋 on 6/6/16.
//  Copyright © 2016 Sheepy. All rights reserved.
//

import Foundation
import CoreBluetooth

struct CellId {
    static let ScannedPeripheral = "ScannedPeripheralCell"
    static let Characteristic = "CharacteristicCell"
}

struct SegueId {
    static let ShowCharacteristics = "ShowCharacteristics"
}

struct RSSILevel {
    static let ValidMinValue = 0
    static let StrongMinValue = -45
    static let MediumMinValue = -65
    static let WeakMinValue = -85
}