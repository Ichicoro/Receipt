//
//  Item.swift
//  Receipt
//
//  Created by Zelda on 15/07/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var uuid: UUID
    var text: String
    var timestamp: Date
    
    init(uuid: UUID, text: String, timestamp: Date) {
        self.uuid = uuid
        self.text = text
        self.timestamp = timestamp
    }
}
