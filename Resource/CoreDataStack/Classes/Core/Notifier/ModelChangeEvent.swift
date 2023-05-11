//
//  ModelChangeEvent.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
import CoreData

public struct ModelChangeEvent {
    private typealias EntityName = String

    private let changeMap: [EntityName: ChangeInfo]

    public var isEmpty: Bool { return changeMap.isEmpty }

    init(notification note: Notification) {
        var changeMap: [EntityName: ChangeInfo] = [:]

        // Common function to handle all cases of changes
        func addObjects(with key: String, of type: ChangeType) {
            guard let set = note.userInfo?[key] as? Set<NSManagedObject>, !set.isEmpty else { return }
            let fragments = set.compactMap { ($0 as? CoreDataFragmentableEntityProtocol)?.modelFragment }
            for fragment in fragments {
                let entityName = Swift.type(of: fragment).entityName
                var changes = changeMap[entityName] ?? ChangeInfo()
                switch type {
                case .created: changes.created.append(fragment)
                case .updated: changes.updated.append(fragment)
                case .deleted: changes.deleted.append(fragment)
                }
                changeMap[entityName] = changes
            }
        }

        addObjects(with: NSInsertedObjectsKey, of: .created)
        addObjects(with: NSUpdatedObjectsKey, of: .updated)
        addObjects(with: NSDeletedObjectsKey, of: .deleted)

        self.changeMap = changeMap
    }

    public func hasChanges(for type: CoreDataFragmentProtocol.Type) -> Bool {
        return changeMap[type.entityName] != nil
    }

    public func hasChanges<T: CoreDataFragmentProtocol>(for type: T.Type, where predicate: (T) -> Bool) -> Bool {
        return filter(type).contains(where: predicate)
    }

    public func filter<T: CoreDataFragmentProtocol>(_ type: T.Type) -> ModelChangeInfo<T> {
        guard let changeInfo = changeMap[type.entityName] else { return ModelChangeInfo<T>() }

        let created = changeInfo.created.compactMap { $0 as? T }
        assert(created.count == changeInfo.created.count)

        let updated = changeInfo.updated.compactMap { $0 as? T }
        assert(updated.count == changeInfo.updated.count)

        let deleted = changeInfo.deleted.compactMap { $0 as? T }
        assert(deleted.count == changeInfo.deleted.count)

        let modelChangeInfo = ModelChangeInfo<T>(created: created, updated: updated, deleted: deleted)
        assert(!modelChangeInfo.isEmpty)

        return modelChangeInfo
    }

    public func filter<T: CoreDataFragmentProtocol>(_ type: T.Type, where predicate: (T) -> Bool) -> ModelChangeInfo<T> {
        let filteredByType = filter(type)
        return ModelChangeInfo(created: filteredByType.created.filter(predicate),
                               updated: filteredByType.updated.filter(predicate),
                               deleted: filteredByType.deleted.filter(predicate))
    }
}

// MARK: - ChangeInfo
extension ModelChangeEvent {
    fileprivate enum ChangeType {
        case created
        case updated
        case deleted
    }

    private struct ChangeInfo: ChangesType {
        var created: [CoreDataFragmentProtocol]
        var updated: [CoreDataFragmentProtocol]
        var deleted: [CoreDataFragmentProtocol]
    }
}

// MARK: - CustomStringConvertible
extension ModelChangeEvent: CustomStringConvertible {
    public var description: String {
        let lines: [String] = changeMap.map { entityName, changeInfo in
            "\(entityName)-\(changeInfo.created.count)-\(changeInfo.updated.count)-\(changeInfo.deleted.count)"
        }
        return "\n" + lines.joined(separator: "\n")
    }
}
