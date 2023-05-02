//
//  Property+Swift.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

extension Property {
    func swiftType(for modelName: String, _ propertyName: String, _ required: Bool = true) -> SwiftType {
        let rawType = rawSwiftType(for: modelName, propertyName)

        switch rawType {
        case .anyCodable:
            return SwiftType(name: "AnyCodable", isOptional: !required, isCustom: false, isArray: false, isAnyCodable: true)
        case .builtIn(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: false, isArray: false)
        case .custom(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: true, isArray: false)
        case .customArray(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: true, isArray: true)
        }
    }

    private enum Kind {
        case anyCodable
        case builtIn(String)
        case custom(String)
        case customArray(String)
    }

    private func rawSwiftType(for modelName: String, _ propertyName: String) -> Kind {
        if enumCases != nil {
            assert(type == "string", "\(modelName): enum rawValues must be strings")
            return .builtIn(propertyName.uppercasedFirst())
        }

        switch type {
        case "array":
            switch items {
            case .property(let prop):
                let type = prop.swiftType(for: modelName, propertyName)
                return .builtIn("[\(type.name)]")
            case .ref(let ref):
                let type = ref.swiftType(isArray: true)
                return .customArray(type.name)
            case .none:
                fatalError("\(modelName): array \(propertyName) has no items")
            }

        case "number":
            switch format {
            case .none, "double": return .builtIn("Double")
            default: fatalError("\(modelName): unknown format \(String(describing: format)) for number property")
            }

        case "object":
            if let additionalProperties = self.additionalProperties {
                switch additionalProperties {
                case .property(let prop):
                    let inner = prop.rawSwiftType(for: modelName, propertyName)
                    switch inner {
                    case .builtIn(let type):
                        return .builtIn("[String: \(type)]")
                    case .custom(let type):
                        return .custom(type)
                    case .customArray(let type):
                        return .customArray(type)
                    case .anyCodable:
                        return .anyCodable
                    }
                case .ref(let ref):
                    let refType = ref.swiftType()
                    return .builtIn("[String: \(refType.propertyType)]")
                }
            } else {
                return .anyCodable
            }

        case "string":
            switch format {
            case .none: return .builtIn("String")
            case "date-time": return .builtIn("Date")
            default: fatalError("\(modelName): unknown string format '\(format!)' for \(propertyName)")
            }

        case "boolean":
            return .builtIn("Bool")

        case "integer":
            return .builtIn("Int")

        case "double":
            return .builtIn("Double")

        default:
            fatalError("\(modelName): unknown type \(type)")
        }
    }
}
