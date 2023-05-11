//
//  CoreData.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
import CoreData
//import SeaFoundation

public struct CoreDataModel {
    public let name: String
    public let bundle: Bundle

    public init(name: String, bundle: Bundle) {
        self.name = name
        self.bundle = bundle
    }
}

public class CoreData: NSObject {
    public let config: CoreDataConfig
    private let model: CoreDataModel
    private let stack: CoreDataStack
    private let changeMulticaster: ModelChangeMulticaster
    
    private let defaultDelegate: CoreDataDelegate?
    private weak var delegate: CoreDataDelegate?
    
    var shouldAssert: Bool = true

    /// Dedicated Initialiser
    /// - Parameter delegate: Weakly captured. Provide an implementation of this if custom behaviour is desired. You can also subclass DefaultCoreDataDelegate.
    public init(config: CoreDataConfig, model: CoreDataModel, delegate: CoreDataDelegate? = nil) {
        self.config = config
        self.model = model
        
        let delegateInUse: CoreDataDelegate
        if let delegate = delegate {
            delegateInUse = delegate
            self.defaultDelegate = nil
            self.delegate = delegate
        } else {
            delegateInUse = DefaultCoreDataDelegate()
            self.defaultDelegate = delegateInUse
            self.delegate = delegateInUse
        }
        
        self.stack = CoreDataStack(params: CoreDataStack.Params(config: config, model: model),
                                   delegate: delegateInUse)
        self.changeMulticaster = ModelChangeMulticaster(coreDataStack: stack)
    }

    public func resetAndDeletePersistentStore() throws {
//        Logger.info()
        try performAndWait(.write) { context in
            context.reset()
            if let allStores = context.persistentStoreCoordinator?.persistentStores {
                try allStores.forEach { store in try context.persistentStoreCoordinator?.remove(store) }
            }
        }

        try performAndWait(.read) { context in
            context.reset()
            if let allStores = context.persistentStoreCoordinator?.persistentStores {
                try allStores.forEach { store in try context.persistentStoreCoordinator?.remove(store) }
            }
        }

        stack.deletePersistentStoreFile()
    }

    public func observeModelChanges(on queue: DispatchQueue = .global(qos: .background),
                                    using block: @escaping (ModelChangeEvent) -> Void) -> ModelChangeObserverCancelToken {
        return changeMulticaster.observeModelChanges(on: queue, with: block)
    }

    public func logEntityRowCounts(reportOn queue: DispatchQueue = .global(qos: .background), completion: ((Result<Void, Error>) -> Void)?) {
        let entities = stack.model.entities
        let modelName = model.name

        return perform(.write, block: { context in
            for entity in entities {
                guard let name = entity.name else { continue }
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let count = try context.count(for: request)
                print("\(modelName) - \(name) - (\(count))")
            }
        }, reportOn: queue, completion: completion)
    }
}

// MARK: - Actions API
extension CoreData {
    public enum ContextType {
        case read
        case write
    }

    func context(of type: ContextType) -> NSManagedObjectContext {
        switch type {
        case .read: return stack.readContext
        case .write: return stack.writeContext
        }
    }

    public func perform<T>(_ type: ContextType, block: @escaping (_ context: NSManagedObjectContext) throws -> T) {
        perform(type, block: block, completion: nil)
    }

    public func perform<T>(_ type: ContextType,
                           block: @escaping (_ context: NSManagedObjectContext) throws -> T,
                           reportOn queue: DispatchQueue = .global(qos: .background),
                           completion: ((Result<T, Error>) -> Void)?) {
        let context = self.context(of: type)
        context.perform {
            do {
                let value = try block(context)
                queue.async {
                    completion?(.success(value))
                }
            } catch {
                if context.hasChanges { context.rollback() }
//                Logger.error("\(error)")
                queue.async {
                    completion?(.failure(error))
                }
            }
        }
    }

    public func performAndWait<T>(_ type: ContextType, block: (_ context: NSManagedObjectContext) throws -> T) throws -> T {
        let context = self.context(of: type)
        let shouldAssert = self.shouldAssert
        var maybeValue: T? = nil
        var maybeError: Error? = nil
        
        context.performAndWait {
            do {
                maybeValue = try block(context)
                
                if maybeValue is NSManagedObject || (maybeValue is [NSManagedObject] && (maybeValue as? [NSManagedObject])?.isEmpty == false) {
                    if shouldAssert {
                        assertionFailure()
                    }
                    
//                    Logger.error("Invalid access of NSManagedObject outside the dedicated queue")
                    throw CoreDataError.invalidAccess
                }
                
            } catch {
                if context.hasChanges { context.rollback() }
//                Logger.error("\(error)")
                maybeError = error
            }
        }
        
        if let error = maybeError { throw error }
        guard let value = maybeValue else { throw CoreDataError.unexpectedNil }
        return value
    }
}
