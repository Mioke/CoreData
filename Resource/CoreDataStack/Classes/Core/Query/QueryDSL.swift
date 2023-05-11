//
//  QueryDSL.swift
//  SeaCoreData
//
//  Created by Omer Iqbal on 10/10/17.
//  Copyright © 2017 Garena. All rights reserved.
//

import Foundation
import CoreData

public protocol PredicateConvertible {
    func toNSPredicate() throws -> NSPredicate
}

public indirect enum Query<Model: KeyPathStringConvertible, Value>  {
    case path(KeyPath<Model, Value>)
    case val(Value)
    case presentIn(KeyPath<Model, Value>, [Value])
    case notPresentIn(KeyPath<Model, Value>, [Value])
    case equal(Query<Model, Value>, Query<Model, Value>)
    case notEqual(Query<Model, Value>, Query<Model, Value>)
    case lt(Query<Model, Value>, Query<Model, Value>)
    case lte(Query<Model, Value>, Query<Model, Value>)
    case gt(Query<Model, Value>, Query<Model, Value>)
    case gte(Query<Model, Value>, Query<Model, Value>)
    case bitwiseAnd(Query<Model, Value>, Query<Model, Value>)
}

extension Query {
    public static func == (lhs: Query, rhs: Query) -> Query {
        return .equal(lhs, rhs)
    }

    public static func != (lhs: Query, rhs: Query) -> Query {
        return .notEqual(lhs, rhs)
    }

    public static func < (lhs: Query, rhs: Query) -> Query {
        return .lt(lhs, rhs)
    }

    public static func <= (lhs: Query, rhs: Query) -> Query {
        return .lte(lhs, rhs)
    }

    public static func > (lhs: Query, rhs: Query) -> Query {
        return .gt(lhs, rhs)
    }

    public static func >= (lhs: Query, rhs: Query) -> Query {
        return .gte(lhs, rhs)
    }

    public static func && <Model, LeftVal, RightVal> (lhs: Query<Model, LeftVal>, rhs: Query<Model, RightVal>) -> CompoundQuery {
        return CompoundQuery.and([lhs, rhs])
    }

    public static func && (lhs: Query, rhs: CompoundQuery) -> CompoundQuery {
        switch rhs {
        case let .and(rPreds): return .and([lhs] + rPreds)
        default: return .and([lhs, rhs])
        }
    }

    public static func & (lhs: Query, rhs: Query) -> Query {
        return .bitwiseAnd(lhs, rhs)
    }
}

extension Query: PredicateConvertible {
    private func formatted() throws -> String {
        switch self {
        case .path(_):
            return "%K"
        case .val(_):
            return "%@"
        default:
            throw QueryError.invalidFormat
        }
    }

    private func literal() throws -> Any {
        switch self {
        case let .path(path):
            return Model.string(from: path)
        case let .val(v):
            return v // TODO
        default:
            throw QueryError.invalidLiteral
        }
    }

    public func toNSPredicate() throws -> NSPredicate {
        switch self {
        case .path(_):
            throw QueryError.invalidPredicate
        case .val(_):
            throw QueryError.invalidPredicate
        case let .presentIn(path, coll):
            let wrappedPath = Query.path(path)
            return NSPredicate(format: "\(try wrappedPath.formatted()) IN %@", argumentArray: [try wrappedPath.literal(), coll])
        case let .notPresentIn(path, coll):
            let wrappedPath = Query.path(path)
            return NSPredicate(format: "NOT (\(try wrappedPath.formatted()) IN %@)", argumentArray: [try wrappedPath.literal(), coll])
        case let .equal(lhs, rhs):
            return NSPredicate(format: "\(try lhs.formatted()) == \(try rhs.formatted())", argumentArray: [try lhs.literal(), try rhs.literal()])
        case let .notEqual(lhs, rhs):
            return NSPredicate(format: "\(try lhs.formatted()) != \(try rhs.formatted())", argumentArray: [try lhs.literal(), try rhs.literal()])
        case let .lt(lhs, rhs):
            return NSPredicate(format: "\(try lhs.formatted()) < \(try rhs.formatted())", argumentArray: [try lhs.literal(), try rhs.literal()])
        case let .lte(lhs, rhs):
            return NSPredicate(format: "\(try lhs.formatted()) <= \(try rhs.formatted())", argumentArray: [try lhs.literal(), try rhs.literal()])
        case let .gt(lhs, rhs):
            return NSPredicate(format: "\(try lhs.formatted()) > \(try rhs.formatted())", argumentArray: [try lhs.literal(), try rhs.literal()])
        case let .gte(lhs, rhs):
            return NSPredicate(format: "\(try lhs.formatted()) >= \(try rhs.formatted())", argumentArray: [try lhs.literal(), try rhs.literal()])
        case let .bitwiseAnd(lhs, rhs):
            return NSPredicate(format: "(\(try lhs.formatted()) & \(try rhs.formatted())) > 0", argumentArray: [try lhs.literal(), try rhs.literal()])
        }
    }
}

public enum CompoundQuery {
    case and([PredicateConvertible])
    case or([PredicateConvertible])
    case not(PredicateConvertible)
}

extension CompoundQuery: PredicateConvertible {
    public func toNSPredicate() throws -> NSPredicate {
        switch self {
        case let .and(preds):
            return NSCompoundPredicate(andPredicateWithSubpredicates: try preds.map {try $0.toNSPredicate()})
        case let .or(preds):
            return NSCompoundPredicate(orPredicateWithSubpredicates: try preds.map {try $0.toNSPredicate()})
        case let .not(pred):
            return NSCompoundPredicate(notPredicateWithSubpredicate: try pred.toNSPredicate())
        }
    }
}

extension CompoundQuery {
    public static func && (lhs: CompoundQuery, rhs: CompoundQuery) -> CompoundQuery {
        return CompoundQuery.and([lhs, rhs])
    }

    public static func && <Model, Value> (lhs: CompoundQuery, rhs: Query<Model, Value>) -> CompoundQuery {
        switch lhs {
        case let .and(lPreds): return .and(lPreds + [rhs])
        default: return .and([lhs, rhs])
        }
    }
}

public enum QueryError: Error {
    case invalidLiteral
    case invalidFormat
    case invalidPredicate
}

// MARK: Convenience
extension Query where Value == NSNumber {
    public static func numVal(_ num: UInt32) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: Int32) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: UInt64) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: Int64) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: Bool) -> Query {
        return .val(NSNumber(value: num))
    }
}

extension Query where Value == NSNumber? {
    public static func numVal(_ num: UInt32) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: Int32) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: UInt64) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: Int64) -> Query {
        return .val(NSNumber(value: num))
    }

    public static func numVal(_ num: Bool) -> Query {
        return .val(NSNumber(value: num))
    }
}

// MARK: - Debugging
extension Query: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case let .path(path):
            return String(describing: path)
        case let .val(value):
            return String(describing: value)
        case let .presentIn(path, values):
            return "\(path) IN \(values)"
        case let .notPresentIn(path, values):
            return "NOT \(path) IN \(values)"
        case let .equal(path, value):
            return "\(path) == \(value)"
        case let .notEqual(path, value):
            return "\(path) != \(value)"
        case let .lt(lhs, rhs):
            return "\(lhs) < \(rhs)"
        case let .lte(lhs, rhs):
            return "\(lhs) <= \(rhs)"
        case let .gt(lhs, rhs):
            return "\(lhs) > \(rhs)"
        case let .gte(lhs, rhs):
            return "\(lhs) >= \(rhs)"
        case let .bitwiseAnd(lhs, rhs):
            return "\(lhs) & \(rhs)"
        }
    }

    public var debugDescription: String {
        return description
    }
}

extension CompoundQuery: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case let .and(components):
            return components.map { "(\($0))" }.joined(separator: " && ")
        case let .or(components):
            return components.map { "(\($0))" }.joined(separator: " || ")
        case let .not(predicate):
            return "NOT \(predicate)"
        }
    }

    public var debugDescription: String {
        return description
    }
}
