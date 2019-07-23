//
//  IndexPath+Row.swift
//  QMobileDataStore
//
//  Created by Quentin Marciset on 23/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

#if os(OSX)

extension IndexPath {

    var row: Int {
        get {
            return item
        }
        set {
            item = newValue
        }
    }
}
#endif
