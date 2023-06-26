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
import ReactiveSwift

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
        
        if let url = Bundle.main.url(forResource: "sticker", withExtension: "webp"),
            let data = try? Data(contentsOf: url) {
            
            let image = UIImage(data: data)
            let iv = UIImageView(image: image)
            view.addSubview(iv)
        }

//        print(path)
//
//        try! self.coredata.performAndWait(.write) { context in
//            let message = try _Message.fetchOrCreate(key: 1, context: context)
//            message.messageId = 1
//            message.content = Data(count: 10)
//            message.timestamp = Int64(Date().timeIntervalSince1970)
//            try context.saveIfNeeded()
//        }
//
////        DispatchQueue.global().async {
//            for i in 20000...30000 {
//                try! self.coredata.performAndWait(.write) { context -> Void in
//                    let chat = try _Chat.fetchOrCreate(key: Int64(i), context: context)
//                    chat.lastMessageId = Int64(i)
//                    chat.name = "Chat \(i)"
//                    chat.type = 1
//                    chat.lastMessage = try _Message.fetch(key: 1, context: context)
//                    try context.saveIfNeeded()
////                } completion: { result in
////                    if case .failure(let e) = result {
////                        print(e)
////                    }
//                }
//            }
////        }
//
//        DispatchQueue.global().async {
//            self.coredata.perform(.write) { context in
//                let theMessage = try _Message.fetch(key: 1, context: context)!
////                context.delete(theMessage)
////                try context.saveIfNeeded()
//
//                for i in 20000...30000 {
//                    let chat = try _Chat.fetchOrCreate(key: Int64(i), context: context)
//                    chat.lastMessageId = Int64(i)
//                    chat.name = "Chat \(i)"
//                    chat.type = 2
//                    if i == 30000 { chat.lastMessage = theMessage }
//                    try context.saveIfNeeded()
//                }
//            } completion: { result in
//                if case .failure(let e) = result {
//                    print(e)
//                }
//            }
//        }
//
//        DispatchQueue.global().async {
//            self.coredata.perform(.write) { context in
//                if let message = try _Message.fetch(key: 1, context: context) {
//                    context.delete(message)
//                    try context.saveIfNeeded()
//                }
//            }
//        }

//        DispatchQueue.global().async {
//            for _ in 20000...21000 {
//                do {
//                    try self.coredata.performAndWait(.write) { context in
//                        if let message = try _Message.fetch(key: 1, context: context) {
//                            message.timestamp = Int64(Date().timeIntervalSince1970)
//                            try context.saveIfNeeded()
//                        }
//                    }
//                } catch {
//                    print(error)
//                }
//                usleep(10 * 1000)
//            }
//        }

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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let sendable = Task {
            let result = try await coredata.perform(.write) { context in
                let result = try _Chat.fetchOrCreate(key: 1, context: context)
                return result.chatID
            }
            return result
        }
        
        SignalProducer<Int64, Error>.task {
            return try await self.coredata.perform(.write) { context in
                let result = try _Chat.fetchOrCreate(key: 1, context: context)
                return result.chatID
            }
        }
        .flatMap(.latest) { chatID in
            print(chatID)
            return SignalProducer<NoValue, Error>.init(value: .none)
        }
        .start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension Chat: CoreDataEntityProtocol {
    public static func entityName() -> String {
        return "Chat"
    }
}
// A mock class for wrap auto-generated class 'Chat'.
final class _Chat: Chat, CoreDataPrimaryKeyEntityProtocol {
    static var primaryKeyPath: KeyPath<_Chat, Int64> = \.chatID
    static var writablePrimaryKeyPath: WritableKeyPath<Chat, Int64> = \.chatID
}


final class _Message: Message, CoreDataPrimaryKeyEntityProtocol {
    static var primaryKeyPath: KeyPath<_Message, Int64> = \.messageId
    static var writablePrimaryKeyPath: WritableKeyPath<Message, Int64> = \.messageId
}

extension Message: CoreDataEntityProtocol {
    public static func entityName() -> String {
        return "Message"
    }
}
