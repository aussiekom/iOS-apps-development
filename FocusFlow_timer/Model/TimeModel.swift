//
//  TimeModel.swift
//  FocusFlow
//
//  Created by Evgeniia Komarova on 08.08.2024.
//

import SwiftUI

struct TimeModel: Hashable {
    var hour: Int = 0
    var minute: Int = 0
    var seconds: Int = 0
    
    var isZero: Bool {
        return hour == 0 && minute == 0 && seconds == 0
    }
    
    var totalInSeconds: Int {
        return (hour * 60 * 60) + (minute * 60) + seconds
    }
}
