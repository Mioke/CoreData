//
//  CoreDataConfig.swift
//  CocoaLumberjack
//
//  Created by Mai Anh Vu on 25/3/19.
//

import Foundation
import CoreData

public enum CoreDataConfig {
    // Configure to use an in-memory storage.
    case inMemory
    // Configure to use a SQLite file at the ABSOLUTE path specified by the associated value.
    case persistent(path: String)
}

extension CoreDataConfig {
    var persistentStoreType: String {
        switch self {
        case .inMemory: return NSInMemoryStoreType
        case .persistent: return NSSQLiteStoreType
        }
    }
}
