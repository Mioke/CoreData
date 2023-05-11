//
//  ReactiveSwift+CoreData.swift
//  SeaCoreData
//
//  Created by Mai Anh Vu on 4/4/19.
//

import Foundation
import ReactiveSwift
import CoreData

extension SignalProducer where Error == Swift.Error {
    public func coreDataFlatMap<Inner>(
        _ coreData: CoreData,
        _ contextType: CoreData.ContextType,
        observeOn scheduler: Scheduler = CoreData.Scheduler.default,
        _ transform: @escaping (NSManagedObjectContext, Value) throws -> Inner
        ) -> SignalProducer<Inner.Value, Error> where Inner: SignalProducerConvertible, Inner.Error == Error {

        return flatMap(.latest) { [weak coreData] value -> SignalProducer<Inner.Value, Error> in
            SignalProducer<Inner.Value, Error> { (observer, lifetime) in
                guard let coreData = coreData else {
                    observer.send(error: CoreDataError.weakError)
                    return
                }
                let context = coreData.context(of: contextType)
                context.perform {
                    guard !lifetime.hasEnded else { observer.sendCompleted(); return }

                    let producer: SignalProducer<Inner.Value, Error>
                    do {
                        producer = try transform(context, value).producer
                    } catch {
                        if context.hasChanges { context.rollback() }
//                        Logger.error("\(error)")
                        observer.send(error: error)
                        return
                    }
                    producer.take(during: lifetime)
                        .on(event: { observer.send($0) })
                        .start()
                }
            }
        }.observe(on: scheduler)
    }
}


/// Holds the `Lifetime` of the object.
private let isSwizzledKey = AssociationKey<Bool>(default: false)

/// Holds the `Lifetime` of the object.
private let lifetimeKey = AssociationKey<Lifetime?>(default: nil)

/// Holds the `Lifetime.Token` of the object.
private let lifetimeTokenKey = AssociationKey<Lifetime.Token?>(default: nil)

extension Lifetime {
    /// Retrive the associated lifetime of given object.
    /// The lifetime ends when the given object is deinitialized.
    ///
    /// - parameters:
    ///   - object: The object for which the lifetime is obtained.
    ///
    /// - returns: The lifetime ends when the given object is deinitialized.
    static func of(_ object: AnyObject) -> Lifetime {
        if let object = object as? NSObject {
            return .of(object)
        }
        
        return synchronized(object) {
            let associations = Associations(object)
            
            if let lifetime = associations.value(forKey: lifetimeKey) {
                return lifetime
            }
            
            let (lifetime, token) = Lifetime.make()
            
            associations.setValue(token, forKey: lifetimeTokenKey)
            associations.setValue(lifetime, forKey: lifetimeKey)
            
            return lifetime
        }
    }
    
    /// Retrive the associated lifetime of given object.
    /// The lifetime ends when the given object is deinitialized.
    ///
    /// - parameters:
    ///   - object: The object for which the lifetime is obtained.
    ///
    /// - returns: The lifetime ends when the given object is deinitialized.
    static func of(_ object: NSObject) -> Lifetime {
        return synchronized(object) {
            if let lifetime = object.associations.value(forKey: lifetimeKey) {
                return lifetime
            }
            
            let (lifetime, token) = Lifetime.make()
            
            let objcClass: AnyClass = (object as AnyObject).objcClass
            let objcClassAssociations = Associations(objcClass as AnyObject)
            
#if swift(>=4.0)
            let deallocSelector = sel_registerName("dealloc")
#else
            let deallocSelector = sel_registerName("dealloc")!
#endif
            
            // Swizzle `-dealloc` so that the lifetime token is released at the
            // beginning of the deallocation chain, and only after the KVO `-dealloc`.
            synchronized(objcClass) {
                // Swizzle the class only if it has not been swizzled before.
                if !objcClassAssociations.value(forKey: isSwizzledKey) {
                    objcClassAssociations.setValue(true, forKey: isSwizzledKey)
                    
                    var existingImpl: IMP? = nil
                    
                    let newImplBlock: @convention(block) (UnsafeRawPointer) -> Void = { objectRef in
                        // A custom trampoline of `objc_setAssociatedObject` is used, since
                        // the imported version has been inserted with ARC calls that would
                        // mess with the object deallocation chain.
                        
                        // Release the lifetime token.
                        unsafeSetAssociatedValue(nil, forKey: lifetimeTokenKey, forObjectAt: objectRef)
                        
                        let impl: IMP
                        
                        // Call the existing implementation if one has been caught. Otherwise,
                        // call the one first available in the superclass hierarchy.
                        if let existingImpl = existingImpl {
                            impl = existingImpl
                        } else {
                            let superclass: AnyClass = class_getSuperclass(objcClass)!
                            impl = class_getMethodImplementation(superclass, deallocSelector)!
                        }
                        
                        typealias Impl = @convention(c) (UnsafeRawPointer, Selector) -> Void
                        unsafeBitCast(impl, to: Impl.self)(objectRef, deallocSelector)
                    }
                    
                    let newImpl =  imp_implementationWithBlock(newImplBlock as Any)
                    
                    if !class_addMethod(objcClass, deallocSelector, newImpl, "v@:") {
                        // The class has an existing `dealloc`. Preserve that as `existingImpl`.
                        let deallocMethod = class_getInstanceMethod(objcClass, deallocSelector)!
                        
                        // Store the existing implementation to `existingImpl` to ensure it is
                        // available before our version is swapped in.
                        existingImpl = method_getImplementation(deallocMethod)
                        
                        // Store the swapped-out implementation to `existingImpl` in case
                        // the implementation has been changed concurrently.
                        existingImpl = method_setImplementation(deallocMethod, newImpl)
                    }
                }
            }
            
            object.associations.setValue(token, forKey: lifetimeTokenKey)
            object.associations.setValue(lifetime, forKey: lifetimeKey)
            
            return lifetime
        }
    }
}

extension Reactive where Base: AnyObject {
    /// Returns a lifetime that ends when the object is deallocated.
    @nonobjc var lifetime: Lifetime {
        return .of(base)
    }
}

internal struct AssociationKey<Value> {
    fileprivate let address: UnsafeRawPointer
    fileprivate let `default`: Value!
    
    /// Create an ObjC association key.
    ///
    /// - warning: The key must be uniqued.
    ///
    /// - parameters:
    ///   - default: The default value, or `nil` to trap on undefined value. It is
    ///              ignored if `Value` is an optional.
    init(default: Value? = nil) {
        self.address = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))
        self.default = `default`
    }
    
    /// Create an ObjC association key from a `StaticString`.
    ///
    /// - precondition: `key` has a pointer representation.
    ///
    /// - parameters:
    ///   - default: The default value, or `nil` to trap on undefined value. It is
    ///              ignored if `Value` is an optional.
    init(_ key: StaticString, default: Value? = nil) {
        assert(key.hasPointerRepresentation)
        self.address = UnsafeRawPointer(key.utf8Start)
        self.default = `default`
    }
    
    /// Create an ObjC association key from a `Selector`.
    ///
    /// - parameters:
    ///   - default: The default value, or `nil` to trap on undefined value. It is
    ///              ignored if `Value` is an optional.
    init(_ key: Selector, default: Value? = nil) {
        self.address = UnsafeRawPointer(key.utf8Start)
        self.default = `default`
    }
}

internal struct Associations<Base: AnyObject> {
    fileprivate let base: Base
    
    init(_ base: Base) {
        self.base = base
    }
}

extension Reactive where Base: NSObjectProtocol {
    /// Retrieve the associated value for the specified key. If the value does not
    /// exist, `initial` would be called and the returned value would be
    /// associated subsequently.
    ///
    /// - parameters:
    ///   - key: An optional key to differentiate different values.
    ///   - initial: The action that supples an initial value.
    ///
    /// - returns: The associated value for the specified key.
    internal func associatedValue<T>(forKey key: StaticString = #function, initial: (Base) -> T) -> T {
        let key = AssociationKey<T?>(key)
        
        if let value = base.associations.value(forKey: key) {
            return value
        }
        
        let value = initial(base)
        base.associations.setValue(value, forKey: key)
        
        return value
    }
}

extension NSObjectProtocol {
    @nonobjc internal var associations: Associations<Self> {
        return Associations(self)
    }
}

extension Associations {
    /// Retrieve the associated value for the specified key.
    ///
    /// - parameters:
    ///   - key: The key.
    ///
    /// - returns: The associated value, or the default value if no value has been
    ///            associated with the key.
    internal func value<Value>(forKey key: AssociationKey<Value>) -> Value {
        return (objc_getAssociatedObject(base, key.address) as! Value?) ?? key.default
    }
    
    /// Retrieve the associated value for the specified key.
    ///
    /// - parameters:
    ///   - key: The key.
    ///
    /// - returns: The associated value, or `nil` if no value is associated with
    ///            the key.
    internal func value<Value>(forKey key: AssociationKey<Value?>) -> Value? {
        return objc_getAssociatedObject(base, key.address) as! Value?
    }
    
    /// Set the associated value for the specified key.
    ///
    /// - parameters:
    ///   - value: The value to be associated.
    ///   - key: The key.
    internal func setValue<Value>(_ value: Value, forKey key: AssociationKey<Value>) {
        objc_setAssociatedObject(base, key.address, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// Set the associated value for the specified key.
    ///
    /// - parameters:
    ///   - value: The value to be associated.
    ///   - key: The key.
    internal func setValue<Value>(_ value: Value?, forKey key: AssociationKey<Value?>) {
        objc_setAssociatedObject(base, key.address, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

import ObjectiveC

/// Set the associated value for the specified key.
///
/// - parameters:
///   - value: The value to be associated.
///   - key: The key.
///   - address: The address of the object.
internal func unsafeSetAssociatedValue<Value>(_ value: Value?, forKey key: AssociationKey<Value>, forObjectAt address: UnsafeRawPointer) {
    _cds_rac_objc_setAssociatedObject(address, key.address, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

internal func synchronized<Result>(_ token: AnyObject, execute: () throws -> Result) rethrows -> Result {
    objc_sync_enter(token)
    defer { objc_sync_exit(token) }
    return try execute()
}

// Signatures defined in `@objc` protocols would be available for ObjC message
// sending via `AnyObject`.
@objc internal protocol ObjCClassReporting {
    // An alias for `-class`, which is unavailable in Swift.
    @objc(class)
    var objcClass: AnyClass! { get }
    
    @objc(methodSignatureForSelector:)
    func objcMethodSignature(for selector: Selector) -> AnyObject
}

extension Selector {
    /// `self` as a pointer. It is uniqued across instances, similar to
    /// `StaticString`.
    internal var utf8Start: UnsafePointer<Int8> {
        return unsafeBitCast(self, to: UnsafePointer<Int8>.self)
    }
}
