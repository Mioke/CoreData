//
//  ModelChangeInfo.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation

public struct ModelChangeInfo<T: CoreDataFragmentProtocol>: ChangesType {
    public let created: [T]
    public let updated: [T]
    public let deleted: [T]

    public init(created: [T], updated: [T], deleted: [T]) {
        self.created = created
        self.updated = updated
        self.deleted = deleted
    }
}
