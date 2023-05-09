//
//  ManagedObjectContext.swift
//  CocoaLumberjack
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
import CoreData

class ManagedObjectContext: NSManagedObjectContext {
    var isSavingAllowed = true

    override init(concurrencyType ct: NSManagedObjectContextConcurrencyType) {
        super.init(concurrencyType: ct)
        self.mergePolicy = NSMergePolicyType.overwriteMergePolicyType
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func save() throws {
        assert(isSavingAllowed, "SAVING IS NOT ALLOWED ON THIS CONTEXT!")
        assert(hasChanges, "WHY ARE YOU SAVING WHEN THERE ARE NO CHANGES?")
        //                                          - Andrew Eng, 2017 -
        try super.save()
    }
}

extension NSManagedObjectContext {
    public func saveIfNeeded() throws {
        do {
            if hasChanges {
                try save()
            }
        } catch {
            throw error
        }
    }
}
