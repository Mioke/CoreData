//
//  CoreDataError.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 4/4/19.
//

import Foundation

public enum CoreDataError: Swift.Error {
    case deallocated
    case invalidAccess
    case unexpectedNil
    case migrationRequired
    case weakError
}

