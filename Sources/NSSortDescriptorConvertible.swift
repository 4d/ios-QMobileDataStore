//
//  NSSortDescriptorConvertible.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol NSSortDescriptorConvertible {

    var sortDescriptor: NSSortDescriptor? { get }

}

public extension NSSortDescriptor {

    var sortDescriptor: NSSortDescriptor? {
        return self
    }

}
