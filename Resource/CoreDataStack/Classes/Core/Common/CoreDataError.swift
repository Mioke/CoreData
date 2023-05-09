//
//  CoreDataError.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 4/4/19.
//

import Foundation

extension CoreDataError {
    public enum Code {
        case deallocated
        case invalidAccess
        case unexpectedNil
        case migrationRequired
    }
}

public struct CoreDataError: Swift.Error {
    public let code: Code
    // Implicit internal initializer
}
