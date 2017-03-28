//
//  NSSortDescriptorConvertible.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol NSSortDescriptorConvertible {

    init(sortDescriptor: NSSortDescriptor)
    var sortDescriptor: NSSortDescriptor? { get }

}
