//
//  ModelChangeMulticaster.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
//import SeaFoundation

class ModelChangeMulticaster {
    private let changeNotifier: ModelChangeNotifier
    private let multicast = Multicast<Observer>()
    private let observeQueue = DispatchQueue(label: "com.seagroup.seacoredata.multicast.observer")

    init(coreDataStack: CoreDataStack) {
        // To ensure read/write multicast's weakObjects on the same serial thread
        changeNotifier = ModelChangeNotifier(updateQueue: observeQueue)
        
        changeNotifier.eventHandler = { [weak self] event in
            self?.multicast.invoke { obs in
                obs.queue.async { obs.block(event) }
            }
        }

        assert(coreDataStack.didMergeChangesHandler == nil)
        coreDataStack.didMergeChangesHandler = { [weak self] event in
            self?.changeNotifier.receiveChangeEvent(event)
        }
    }

    func observeModelChanges(on queue: DispatchQueue, with block: @escaping (ModelChangeEvent) -> Void) -> ModelChangeObserverCancelToken {
        let observer = Observer(block: block, queue: queue)
        let token = ObservationToken(observer: observer, multicaster: self)
        return token
    }
    
    private func append(observer: ModelChangeMulticaster.Observer) {
        observeQueue.async { [weak self] in
            self?.multicast.append(observer)
        }
    }
    
    private func remove(observer: ModelChangeMulticaster.Observer) {
        observeQueue.async { [weak self] in
            self?.multicast.remove(observer)
        }
    }
}

// MARK: - Helper Structures
public protocol ModelChangeObserverCancelToken {
    func cancel()
}

struct EmptyCancelToken: ModelChangeObserverCancelToken {
    func cancel() {
        // Do nothing
    }
}

extension ModelChangeMulticaster {
    private class ObservationToken: ModelChangeObserverCancelToken {
        let observer: Observer
        private weak var multicaster: ModelChangeMulticaster?

        init(observer: Observer, multicaster: ModelChangeMulticaster) {
            self.observer = observer
            self.multicaster = multicaster
            
            multicaster.append(observer: observer)
        }

        func cancel() {
            multicaster?.remove(observer: observer)
        }
    }

    private class Observer {
        let block: (ModelChangeEvent) -> Void
        let queue: DispatchQueue

        init(block: @escaping (ModelChangeEvent) -> Void, queue: DispatchQueue) {
            self.block = block
            self.queue = queue
        }
    }
}
