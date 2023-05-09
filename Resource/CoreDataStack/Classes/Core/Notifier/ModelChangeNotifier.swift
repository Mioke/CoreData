//
//  ModelChangeNotifier.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 20/3/19.
//

import Foundation
import CoreData

class ModelChangeNotifier {
    var eventHandler: ((ModelChangeEvent) -> Void)?
    private let updateQueue: DispatchQueue
    
    init(updateQueue: DispatchQueue) {
        self.updateQueue = updateQueue
    }

    func receiveChangeEvent(_ event: ModelChangeEvent) {
        guard !event.isEmpty else { return }
        updateQueue.async { [weak self] in
//            Logger.info("\(event)")
            self?.eventHandler?(event)
        }
    }
}
