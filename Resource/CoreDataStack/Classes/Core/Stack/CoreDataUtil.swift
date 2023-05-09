//
//  CoreDataUtil.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
//import SeaLogger
import CoreData

class CoreDataUtil {

    private init() {}
    private static var fileManager: FileManager { return .default }

    static func storeURL(forFilePath filePath: String) -> URL {
        return URL(fileURLWithPath: filePath)
    }

    static func deleteStore(at storeURL: URL) {
        do {
            try fileManager.removeItem(at: storeURL)
//            Logger.info("Deleted store at \(storeURL)")
        } catch {
//            Logger.error("Unable to delete persistent store file")
        }
    }

    static func createManagedObjectModel(model: CoreDataModel) -> NSManagedObjectModel {
        let url = model.bundle.url(forResource: model.name, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: url)!
    }

    static func createPersistentStoreCoordinator(for model: NSManagedObjectModel,
                                                 params: CoreDataStack.Params,
                                                 delegate: CoreDataDelegate) -> NSPersistentStoreCoordinator {
        if let storeURL = params.storeURL {
//            Logger.info("Store URL: \(storeURL.path)")
        }
        
        delegate.coreDataWillOpenDatabaseConnection()

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true]
        do {
            try coordinator.addPersistentStore(ofType: params.storeType, configurationName: nil, at: params.storeURL, options: options)
        } catch {
//            Logger.error("Error adding persistent store: \(error)")
            
            if delegate.coreDataShouldResetPersistenceStore(onError: error) {
                // Delete existing store
                if let storeURL = params.storeURL {
                    do {
                        try fileManager.removeItem(at: storeURL)
//                        Logger.error("Deleted: \(storeURL)")
                    } catch {
//                        Logger.error("Error deleting: \(storeURL), error: \(error)")
                    }
                }

                // Create a new store
                do {
                    try coordinator.addPersistentStore(ofType: params.storeType, configurationName: nil, at: params.storeURL, options: options)
                } catch {
                    assertionFailure(error.localizedDescription)
//                    Logger.error("Error creating new store: \(String(describing: params.storeURL)), error: \(error)")
                }
            }
        }

        
        
        return coordinator
    }

    static func createDirectoryIfNeeded(at url: URL) {
        let directoryPath = url.deletingLastPathComponent().path
        guard !fileManager.fileExists(atPath: directoryPath) else {
            return
        }
        do {
            try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
//            Logger.error("path: \(directoryPath), error: \(error)")
        }
    }
}
