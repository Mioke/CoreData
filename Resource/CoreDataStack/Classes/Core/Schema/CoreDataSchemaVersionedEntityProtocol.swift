//
//  CoreDataSchemaVersionedEntityProtocol.swift
//  SeaTalkCore
//
//  Created by Kunzhen Wang on 1/10/18.
//  Copyright © 2018 Garena. All rights reserved.
//

import Foundation

public protocol CoreDataSchemaVersionedEntityProtocol: class {
    associatedtype Version: Comparable
    associatedtype SchemaVersion: Comparable
    
    var schemaVersionValue: SchemaVersion { get set }
    var versionValue: Version { get set }
    
    static var currentSchemaVersion: SchemaVersion { get }
}

extension CoreDataSchemaVersionedEntityProtocol {
    public func isVersionOutdated(againstVersion version: Version) -> Bool {
        if isSchemaVersionOutdated() {
            return true
        }
        
        return versionValue < version
    }
    
    public func updateVersion(to version: Version) {
        if versionValue < version {
            versionValue = version
        }
        
        if isSchemaVersionOutdated() {
            schemaVersionValue = Self.currentSchemaVersion
        }
    }
    
    public func isSchemaVersionOutdated() -> Bool {
        return schemaVersionValue != Self.currentSchemaVersion
    }
}
