//
//  FileManager+QMobile.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

extension FileManager {

    func removeItemIfExists(atPath path: String) throws {
        if self.fileExists(atPath: path) {
            try self.removeItem(atPath: path)
        }
    }

    func removeItemIfExists(at url: URL) throws {
        if self.fileExists(at: url) {
            try self.removeItem(at: url)
        }
    }

    func fileExists(at url: URL) -> Bool {
        if url.isFileURL {
            return fileExists(atPath: url.path)
        }
        return false
    }

}
