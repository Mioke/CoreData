//
//  CoreDataEntityProtocol.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 22/3/19.
//

import Foundation
import CoreData

public protocol CoreDataEntityProtocol: NSFetchRequestResult {
    static func entityName() -> String
}

public protocol CoreDataFragmentProtocol {
    static var entityName: String { get }
}

public protocol CoreDataFragmentableEntityProtocol: CoreDataEntityProtocol {
    var modelFragment: CoreDataFragmentProtocol { get }
}
