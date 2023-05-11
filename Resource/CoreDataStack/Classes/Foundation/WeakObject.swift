//
//  WeakObject.swift
//  SeaFoundation
//
//  Created by Vincent Nguyen on 27/12/17.
//  Copyright © 2017 Sea Ltd. All rights reserved.
//

import Foundation

final public class WeakObject<T: AnyObject> {
    
    public weak var object: T?
    
    public init(object: T) {
        self.object = object
    }
    
    public convenience init(_ object: T) {
        self.init(object: object)
    }
}

extension NSObjectProtocol {
    public var weakObject: WeakObject<Self> {
        return WeakObject(self)
    }
}
