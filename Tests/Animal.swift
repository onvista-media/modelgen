//
//  Animal.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

import Foundation

public enum Animal: Codable {
    case cat(Cat)
    case dog(Dog)

    public init(from decoder: Decoder) throws {
        if let obj = try? Cat(from: decoder), obj.status == "cat" {
            self = .cat(obj)
        } else if let obj = try? Dog(from: decoder), obj.status == "dog" {
            self = .dog(obj)
        } else {
            enum DiscriminatorKeys: String, CodingKey {
                case type = "status"
            }
            let container = try decoder.container(keyedBy: DiscriminatorKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            throw DecodingError.typeMismatch(Animal.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unexpected subclass type \(type)"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .cat(let obj): try obj.encode(to: encoder)
        case .dog(let obj): try obj.encode(to: encoder)
        }
    }
}

public protocol AnimalProtocol {
    var status: String { get }
}

extension Animal: AnimalProtocol {
    public var status: String {
        switch self {
        case .cat(let obj): return obj.status
        case .dog(let obj): return obj.status
        }
    }

}

public struct Dog: Codable {
    // MARK: - inherited properties from Animal
    public let status: String

    // MARK: - Dog properties
    public let barks: Bool

    public init(status: String, barks: Bool) {
        // MARK: - inherited properties from Animal
        self.status = status
        // MARK: - Dog properties
        self.barks = barks
    }
}

extension Dog: AnimalProtocol {}

public struct Cat: Codable {
    // MARK: - inherited properties from Animal
    public let status: String

    // MARK: - Car properties
    public let meows: Bool

    public init(status: String, meows: Bool) {
        // MARK: - inherited properties from Animal
        self.status = status
        // MARK: - Cat properties
        self.meows = meows
    }
}

extension Cat: AnimalProtocol {}
