//
//  CoreDataErrorHandler.swift
//  SeaCoreData
//
//  Created by Kunzhen Wang on 9/6/21.
//

import Foundation
import CoreData
//import SeaLogger

public protocol CoreDataDelegate: AnyObject {
    func coreDataWillOpenDatabaseConnection()
    func coreDataShouldResetPersistenceStore(onError error: Error) -> Bool
}

open class DefaultCoreDataDelegate: CoreDataDelegate {
    public init() {}
    
    open func coreDataWillOpenDatabaseConnection() {
        
    }
    
    open func coreDataShouldResetPersistenceStore(onError error: Error) -> Bool {
//        Logger.error("Error adding persistent store: \(error)")
        
        if (error as NSError).isCoreDataFileRecoverableError {
//            Logger.error("Couldn't open DB file. Terminating the app... \(error)")
//            SeaLogger.Logger.flush()
            exit(EXIT_SUCCESS)
        }
        
        // https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files?language=objc
        // If the db file is still protected (such as app launched by callkit before first unlocking), then shouldn't delete it.
        if (error as NSError).isCoreDataDBFileProtectedError {
//            Logger.error("DB file is protected. Terminating the app...")
//            SeaLogger.Logger.flush()
            exit(EXIT_SUCCESS)
        }
        
        return true
    }
}

extension NSError {
    public struct SQLiteErrorCode {
        // https://www.sqlite.org/rescode.html
        public static let authError = 23
        public static let ioErrorWrite = 778
        public static let dbCorrupted = 11 // SQLITE_CORRUPT
        public static let noLFS = 22 // SQLITE_NOLFS
        public static let invalidDBFile = 26 // SQLITE_NOTADB
        public static let dbSequenceCorrupted = 523 // SQLITE_CORRUPT_SEQUENCE
    }
    
    public var isCoreDataDBFileProtectedError: Bool {
        if domain == NSCocoaErrorDomain, code == NSFileReadUnknownError,
            let sqliteCode = userInfo[NSSQLiteErrorDomain] as? Int,
            sqliteCode == SQLiteErrorCode.authError {
            return true
        }
        
        if domain == NSSQLiteErrorDomain, code == SQLiteErrorCode.ioErrorWrite {
            return true
        }
        
        return false
    }
    
    public var isCoreDataFileRecoverableError: Bool {
        if domain == NSCocoaErrorDomain {
            switch code {
            case NSFileReadCorruptFileError,
                 NSFileReadTooLargeError:
                return false
            default:
                return true
            }
        }
        
        if domain == NSSQLiteErrorDomain {
            switch code {
            case SQLiteErrorCode.dbCorrupted,
                 SQLiteErrorCode.noLFS,
                 SQLiteErrorCode.invalidDBFile,
                 SQLiteErrorCode.dbSequenceCorrupted:
                return false
            default:
                return true
            }
        }
        
        return true
    }
}
