//
//  FetchRequestBuilder.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 22/3/19.
//

import Foundation
import CoreData

public class FetchRequestBuilder<Model: CoreDataEntityProtocol> {
    public let query: PredicateConvertible?
    public let request: NSFetchRequest<Model>

    public init(query: PredicateConvertible?) {
        self.query = query

        self.request = NSFetchRequest(entityName: Model.entityName())
        do {
            self.request.predicate = try query?.toNSPredicate()
        } catch {
//            Logger.error("\(error)")
        }
    }
}

extension NSManagedObjectContext {
    public func fetch<Model: CoreDataEntityProtocol>(builder: FetchRequestBuilder<Model>) throws -> [Model] {
        return try fetch(builder.request)
    }
}
