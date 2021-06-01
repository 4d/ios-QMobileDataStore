//
//  NSSortDescriptorConvertible.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol NSSortDescriptorConvertible {

    var sortDescriptor: NSSortDescriptor { get }
    func sortDescriptor(ascending: Bool) -> NSSortDescriptor

}

extension NSSortDescriptor: NSSortDescriptorConvertible {

    public var sortDescriptor: NSSortDescriptor {
        return self
    }

    public func sortDescriptor(ascending: Bool) -> NSSortDescriptor {
        return NSSortDescriptor(key: self.key, ascending: ascending)
    }

}
