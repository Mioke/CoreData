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

/// If an entity has a primary key, and it shouldn't be duplicated, this protocol helps you create or fetch the entity
/// using the key you defined.
/// - For example, if codegen model is `Object`, you should create a `final class _Object` subclass from
///   `Object` and then comform to this protocol.
public protocol CoreDataPrimaryKeyEntityProtocol: CoreDataEntityProtocol & KeyPathStringConvertible {
    associatedtype EntityType: NSManagedObject & CoreDataEntityProtocol
    associatedtype KeyType: Equatable
    
    static var primaryKeyPath: KeyPath<Self, KeyType> { get }
    static var writablePrimaryKeyPath: WritableKeyPath<EntityType, KeyType> { get }
}

public extension CoreDataPrimaryKeyEntityProtocol where Self: NSManagedObject {

    static func fetch(key value: KeyType, context: NSManagedObjectContext) throws -> EntityType? {
        let query: Query = .path(primaryKeyPath) == .val(value)
        let builder = FetchRequestBuilder<EntityType>(query: query)
        builder.request.fetchLimit = 1
        return try context.fetch(builder: builder).first
    }

    static func fetchOrCreate(key value: KeyType, context: NSManagedObjectContext) throws -> EntityType {
        if let exist = try fetch(key: value, context: context) {
            return exist
        } else {
            var creation = EntityType(context: context)
            creation[keyPath: writablePrimaryKeyPath] = value
            return creation
        }
    }
    
    
}
