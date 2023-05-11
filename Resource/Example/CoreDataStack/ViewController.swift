//
//  ViewController.swift
//  CoreDataStack
//
//  Created by KelanJiang on 05/09/2023.
//  Copyright (c) 2023 KelanJiang. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack

let path = try! FileManager.default
    .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    .appendingPathComponent("store.db")
    .path

class ViewController: UIViewController {

    let coredata = CoreData(
        config: .persistent(path: path),
        model: .init(name: "Store", bundle: Bundle.main))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print(path)
        
        DispatchQueue.global().async {
            for i in 20000...21000 {
                self.coredata.perform(.write) { context in
                    let chat = try _Chat.upsert(chatID: Int64(i), context: context)
                    chat.lastMessageId = Int64(i)
                    chat.name = "Chat \(i)"
                    chat.type = 1
                    try context.saveIfNeeded()
                } completion: { result in
                    if case .failure(let e) = result {
                        print(e)
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            for i in 20000...21000 {
                self.coredata.perform(.write) { context in
                    let chat = try _Chat.upsert(chatID: Int64(i), context: context)
                    chat.lastMessageId = Int64(i)
                    chat.name = "Chat \(i)"
                    chat.type = 1
                    try context.saveIfNeeded()
                } completion: { result in
                    if case .failure(let e) = result {
                        print(e)
                    }
                }
            }
        }
        
//        DispatchQueue.global().async {
//            for i in 20000...21000 {
//                do {
//                    try coredata.performAndWait(.read) { context in
//                        let result = try _Chat.fetch(chatID: Int64(i), context: context)
//                        print(result as Any)
//                    }
//                } catch {
//                    print(error)
//                }
//                usleep(100 * 1000)
//            }
//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// A mock class for wrap auto-generated class 'Chat'.
final class _Chat: Chat, KeyPathStringConvertible {
    
    class func fetch(chatID: Int64, context: NSManagedObjectContext) throws -> Chat? {
        let query: Query = .path(\_Chat.chatID) == .val(chatID)
        let builder = FetchRequestBuilder<Chat>(query: query)
        let result = try context.fetch(builder: builder)
        return result.first
    }
    
    class func upsert(chatID: Int64, context: NSManagedObjectContext) throws -> Chat {
        if let exist = try fetch(chatID: chatID, context: context) {
            return exist
        } else {
            let chat = Chat(context: context)
            chat.chatID = chatID
            return chat
        }
    }
}

extension Chat: CoreDataEntityProtocol {
    public static func entityName() -> String {
        return "Chat"
    }
}

