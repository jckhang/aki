//
//  Item.swift
//  Aki
//
//  Created by JYXC- DZ-0100219 on 2025/2/8.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
