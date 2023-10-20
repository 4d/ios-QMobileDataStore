//
//  DataStore+Preferences.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 05/05/2017.
//  Copyright © 20223 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

extension Prephirences {

    public struct DataStore {

        static let instance = MutableProxyPreferences(preferences: sharedMutableInstance!, key: "dataStore.") // swiftlint:disable:this superfluous_disable_command force_cast

        /// Load data from embedded files. Default true.
        public static let bachDelete = instance["bachDelete"] as? Bool ?? true

    }
}
