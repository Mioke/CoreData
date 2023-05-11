//
//  CoreData+Reactive.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
import ReactiveSwift
import CoreData

// MARK: - Model Change Signals
extension CoreData {
    
    private static var coreDataSignalKey: StaticString = "coredata.modelchange.signal"
    private static var coreDataObserverKey: StaticString = "coredata.modelchange.observer"
    
    public var modelChangeSignal: Signal<ModelChangeEvent, Never> {
        return modelChanges()
    }
    
    public func modelChanges(observeOn scheduler: QueueScheduler = Scheduler.default) -> Signal<ModelChangeEvent, Never> {
        
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        if let signal = objc_getAssociatedObject(self, &CoreData.coreDataSignalKey) as? Signal<ModelChangeEvent, Never> {
            return signal
        }
        
        let (signal, observer) = Signal<ModelChangeEvent, Never>.pipe()
        
        let token = observeModelChanges(on: scheduler.queue) { [weak observer] (event) in
            observer?.send(value: event)
        }
        
        Lifetime.of(self).observeEnded { [weak observer] in
            observer?.sendCompleted()
            token.cancel()
        }
        
        objc_setAssociatedObject(self, &CoreData.coreDataObserverKey, observer, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, &CoreData.coreDataSignalKey, signal, .OBJC_ASSOCIATION_RETAIN)
        
        return signal
    }
    
    public func modelChanges<T: CoreDataFragmentProtocol>(
        for type: T.Type,
        observeOn scheduler: QueueScheduler = Scheduler.default
    ) -> Signal<ModelChangeInfo<T>, Never> {
        return modelChanges(observeOn: scheduler)
            .filter { $0.hasChanges(for: type) }
            .map { $0.filter(type) }
    }
    
    public func modelChanges<T: CoreDataFragmentProtocol>(for type: T.Type,
                                                          observeOn scheduler: QueueScheduler = Scheduler.default,
                                                          where predicate: @escaping (T) -> Bool
    ) -> Signal<ModelChangeInfo<T>, Never> {
        
        return modelChanges(observeOn: scheduler).compactMap { event -> ModelChangeInfo<T>? in
            let changeInfo = event.filter(type, where: predicate)
            guard !changeInfo.isEmpty else { return nil }
            return changeInfo
        }
    }
    
    public struct Scheduler {
        public static let `default` = QueueScheduler(qos: .background)
    }
}

// MARK: - Convenient Signal Producers
extension Reactive where Base: CoreData {
    public func flatMap<Inner: SignalProducerConvertible>(
        _ contextType: CoreData.ContextType,
        observeOn scheduler: Scheduler = CoreData.Scheduler.default,
        with transform: @escaping (_ context: NSManagedObjectContext) throws -> Inner
    ) -> SignalProducer<Inner.Value, Swift.Error> where Inner.Error == Swift.Error {
        
        let shouldAssert = base.shouldAssert
        return SignalProducer<NoValue, Swift.Error>(value: .none).coreDataFlatMap(base, contextType, observeOn: scheduler) { context, _ -> Inner in
            return try transform(context)
        }.flatMap(.latest) { (val) -> SignalProducer<Inner.Value, Swift.Error> in
            if val is NSManagedObject || (val is [NSManagedObject] && (val as? [NSManagedObject])?.isEmpty == false) {
                if shouldAssert { assertionFailure() }
                //                    Logger.error("Invalid access of NSManagedObject outside of dedicated account")
                return .error(CoreDataError.invalidAccess)
            } else {
                return .value(val)
            }
        }
    }
    
    public func map<T>(_ contextType: CoreData.ContextType,
                       observeOn scheduler: Scheduler = CoreData.Scheduler.default,
                       with transform: @escaping (_ context: NSManagedObjectContext) throws -> T
    ) -> SignalProducer<T, Swift.Error> {
        
        let shouldAssert = base.shouldAssert
        return flatMap(contextType, observeOn: scheduler) { context -> SignalProducer<T, Swift.Error> in
            let val = try transform(context)
            if val is NSManagedObject || (val is [NSManagedObject] && (val as? [NSManagedObject])?.isEmpty == false) {
                if shouldAssert { assertionFailure() }
                //                Logger.error("Invalid access of NSManagedObject outside of dedicated account")
                return .error(CoreDataError.invalidAccess)
            } else {
                return .value(val)
            }
        }
    }
}

extension Reactive where Base: CoreData {
    public func logEntityRowCounts(observeOn scheduler: QueueScheduler = CoreData.Scheduler.default) -> SignalProducer<NoValue, Error> {
        return SignalProducer { [weak base] observer, _ in
            guard let base = base else { return observer.send(error: CoreDataError.weakError) }
            return base.logEntityRowCounts(reportOn: scheduler.queue) { result in
                switch result {
                case .success:
                    observer.complete(with: .none)
                case let .failure(error):
                    observer.send(error: error)
                }
            }
        }
    }
}


// MARK: - Generic
extension SignalProducer {
    public init(_ deferHandler: @escaping () -> SignalProducer<Value, Error>) {
        self.init { (observer, disposable) in
            disposable += deferHandler().start(observer)
        }
    }
    
    public static func value(_ value: Value) -> SignalProducer<Value, Error> {
        return SignalProducer<Value, Error>(value: value)
    }
    
    public static func error(_ error: Error) -> SignalProducer<Value, Error> {
        return SignalProducer<Value, Error>(error: error)
    }
    
    public func defaultsToNilOnError() -> SignalProducer<Value?, Never> {
        return map { $0 as Value? }.flatMapError { _ in SignalProducer<Value?, Never>(value: nil) }
    }
    
    public func observeOnMain() -> SignalProducer<Value, Error> {
        return observe(on: QueueScheduler.main)
    }
}

extension Signal.Observer {
    public func complete(with value: Value) {
        send(value: value)
        sendCompleted()
    }
}
