//
//  ReactiveSwift+Cuncurrency.swift
//  CoreDataStack_Example
//
//  Created by KelanJiang on 2023/5/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import ReactiveSwift

extension SignalProducer where Error == Swift.Error {
    
    /// Bridging function for async functions
    /// - Parameter task: Create aync task.
    /// - Returns: A signal producer running the task.
    static func task(_ task: @escaping () async throws -> Value) -> Self {
        return SignalProducer<Value, Error>.init { ob, lt -> Void in
            Task {
                do {
                    let value = try await task()
                    ob.send(value: value)
                    ob.sendCompleted()
                } catch {
                    ob.send(error: error)
                }
            }
        }
    }
}

struct A<Error: Swift.Error> {
    let name: String
}

struct B<Error: Swift.Error> {
    let name: String
}

extension B {
    var a: A<Error> {
        return .init(name: name)
    }
}

@available(iOS 13, *)
public extension Signal where Error == any Swift.Error {
    
    var values: AsyncThrowingStream<Value, Error> {
        return AsyncThrowingStream<Value, Error> { continuation in
            let disposable = self.on(failed: { error in
                continuation.finish(throwing: error)
            }, completed: {
                continuation.finish()
            }, disposed: {
                continuation.onTermination?(.cancelled)
            }, value: { value in
                continuation.yield(value)
            })
                .producer
                .start()
            
            continuation.onTermination = { termination in
                disposable.dispose()
            }
        }
    }
}
