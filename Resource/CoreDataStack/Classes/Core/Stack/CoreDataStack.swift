//
//  CoreDataStack.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
import CoreData

fileprivate typealias Util = CoreDataUtil

class CoreDataStack {

    // MARK: - Properties
    private let params: Params
    let model: NSManagedObjectModel
    private let internalReadContext: ManagedObjectContext
    private let internalWriteContext: ManagedObjectContext
    private var notificationObserver: AnyObject?

    private var notificationCenter: NotificationCenter { return .default }

    struct Params {
        let storeType: String
        let storeURL: URL?
        let model: CoreDataModel
    }

    var didMergeChangesHandler: ((_ event: ModelChangeEvent) -> Void)? = nil
    private let changesNotifierQueue = DispatchQueue(label: "com.seagroup.SeaCoreData.CoreDataStack.changesNotifierQueue", qos: .default, attributes: .concurrent)

    // MARK: - Initialization
    init(params: Params, delegate: CoreDataDelegate) {
        self.params = params

        if let storeURL = params.storeURL {
            Util.createDirectoryIfNeeded(at: storeURL)
        }

        model = Util.createManagedObjectModel(model: params.model)

        internalReadContext = ManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        internalReadContext.isSavingAllowed = false
        let readPSC = Util.createPersistentStoreCoordinator(for: model, params: params, delegate: delegate)
        internalReadContext.persistentStoreCoordinator = readPSC

        internalWriteContext = ManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        internalWriteContext.isSavingAllowed = true

        // Write persistent store coordinator is either the same instance or a different instance
        // than the read persistent store coordinator, depending on the type.
        let writePSC: NSPersistentStoreCoordinator
        switch params.storeType {
        case NSSQLiteStoreType, NSBinaryStoreType:
            writePSC = Util.createPersistentStoreCoordinator(for: model, params: params, delegate: delegate)
        case NSInMemoryStoreType:
            fallthrough
        default:
            writePSC = readPSC
        }

        internalWriteContext.persistentStoreCoordinator = writePSC

        notificationObserver = notificationCenter.addObserver(forName: .NSManagedObjectContextDidSave, object: internalWriteContext, queue: nil) { [weak self] note in
            let event = ModelChangeEvent(notification: note)
            self?.internalReadContext.perform { [weak self] in
                self?.internalReadContext.mergeChanges(fromContextDidSave: note)
                self?.changesNotifierQueue.async { [weak self] in
                    self?.didMergeChangesHandler?(event)
                }
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            notificationCenter.removeObserver(observer)
            notificationObserver = nil
        }
    }
}

// MARK: - Params
extension CoreDataStack.Params {
    init(config: CoreDataConfig, model: CoreDataModel) {
        storeType = config.persistentStoreType
        switch config {
        case .inMemory: storeURL = nil
        case let .persistent(path): storeURL = Util.storeURL(forFilePath: path)
        }
        self.model = model
    }
}

extension CoreDataStack {
    func deletePersistentStoreFile() {
//        Logger.info()
        guard let storeURL = params.storeURL else { return }
        Util.deleteStore(at: storeURL)
    }
}

extension CoreDataStack {
    var readContext: NSManagedObjectContext { return internalReadContext }
    var writeContext: NSManagedObjectContext { return internalWriteContext }
}

