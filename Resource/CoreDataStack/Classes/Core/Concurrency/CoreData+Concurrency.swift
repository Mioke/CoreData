//
//  CoreData+Concurrency.swift
//  CoreDataStack
//
//  Created by KelanJiang on 2023/5/17.
//

import Foundation
import CoreData

extension CoreData {
    
    public func perform<T>(_ type: ContextType,
                           block: @escaping (_ context: NSManagedObjectContext) throws -> T) async throws -> T {
        let context = self.context(of: type)
        
        if #available(iOS 15.0, *) {
            return try await context.perform(schedule: .enqueued) {
                do {
                    let value = try block(context)
                    try self.resultValueCheck(with: value)
                    return value
                } catch {
                    if context.hasChanges { context.rollback() }
                    throw error
                }
            }
        } else {
            var maybeValue: T? = nil
            var maybeError: Error? = nil
            
            context.performAndWait {
                do {
                    maybeValue = try block(context)
                    try self.resultValueCheck(with: maybeValue)
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
}
