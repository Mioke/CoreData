//
//  ChangesType.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation

public protocol ChangesType {
    associatedtype ModelT

    var created: [ModelT] { get }
    var updated: [ModelT] { get }
    var deleted: [ModelT] { get }

    init(created: [ModelT], updated: [ModelT], deleted: [ModelT])
}

extension ChangesType {
    public init() {
        self.init(created: [], updated: [], deleted: [])
    }
    public init(created: [ModelT]) {
        self.init(created: created, updated: [], deleted: [])
    }
    public init(updated: [ModelT]) {
        self.init(created: [], updated: updated, deleted: [])
    }
    public init(deleted: [ModelT]) {
        self.init(created: [], updated: [], deleted: deleted)
    }
}

extension ChangesType {
    public var isEmpty: Bool {
        return created.isEmpty && updated.isEmpty && deleted.isEmpty
    }

    public func all() -> [ModelT] {
        return created + updated + deleted
    }

    public func contains(where predicate: (ModelT) throws -> Bool) rethrows -> Bool {
        return try created.contains(where: predicate) ||
            updated.contains(where: predicate) ||
            deleted.contains(where: predicate)
    }

    public func filter(_ isIncluded: (ModelT) throws -> Bool) rethrows -> Self {
        return try Self.init(created: created.filter(isIncluded),
                             updated: updated.filter(isIncluded),
                             deleted: deleted.filter(isIncluded))
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        return Self.init(created: lhs.created + rhs.created,
                         updated: lhs.created + rhs.created,
                         deleted: lhs.deleted + rhs.deleted)
    }
}
