//
//  Muticast.swift
//  SeaFoundation
//
//  Created by Vincent Nguyen on 28/12/17.
//  Copyright © 2017 Sea Ltd. All rights reserved.
//

import Foundation

public protocol Multicastable {
    
    associatedtype Events
    
    var multicast: Multicast<Events> { get }
}

public extension Multicastable {
    
    func subscribeEvents(_ subscriber: Events) {
        multicast.append(subscriber)
    }
    func unsubscribeEvents(_ subscriber: Events) {
        multicast.remove(subscriber)
    }
}


final public class Multicast<T> {
    
    private var weakObjects: [WeakObject<AnyObject>] = []
    
    public init() {}
    
    public func append(_ object: T) {
        let object = object as AnyObject
        weakObjects.append(WeakObject(object: object))
    }
    
    public func remove(_ object: T) {
        let object = object as AnyObject
        weakObjects = weakObjects.filter { $0.object !== object }
    }
    
    public func invoke(_ function: (T) -> ()) {
        
        for weakObject in weakObjects {
            if let object = weakObject.object as? T {
                function(object)
            }
        }
        weakObjects = weakObjects.filter { $0.object != nil }
    }
    
    public func invokeMain(_ function: @escaping (T) -> ()) {
        DispatchQueue.main.async(execute: { [weak self] in
            self?.invoke(function)
            }
        )
    }
}
