//
//  KeyPathStringConvertible.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
import CoreData

public protocol KeyPathStringConvertible {
    static func string<Value>(from keyPath: KeyPath<Self, Value>) -> String
}

extension KeyPathStringConvertible where Self: NSManagedObject {
    public static func string<Value>(from keyPath: KeyPath<Self, Value>) -> String {
        return keyPath._kvcKeyPathString ?? ""
    }
}
