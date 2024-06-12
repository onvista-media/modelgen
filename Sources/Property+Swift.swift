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
            return SwiftType(name: "AnyCodable", isOptional: !required, isCustom: false, qualifier: .scalar, isAnyCodable: true)
        case .builtInScalar(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: false, qualifier: .scalar)
        case .builtInArray(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: false, qualifier: .array)
        case .builtInDictionary(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: false, qualifier: .dictionary)
        case .custom(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: true, qualifier: .scalar)
        case .customArray(let type):
            return SwiftType(name: type, isOptional: !required, isCustom: true, qualifier: .array)
        }
    }

    private enum Kind {
        case anyCodable
        case builtInScalar(String)
        case builtInArray(String)
        case builtInDictionary(String)
        case custom(String)
        case customArray(String)
    }

    private func rawSwiftType(for modelName: String, _ propertyName: String) -> Kind {
        if enumCases != nil {
            if type == "array" {
                return .builtInArray("String")
            }
            assert(type == "string", "\(modelName): enum rawValues must be strings")
            return .builtInScalar(propertyName.uppercasedFirst())
        }

        switch type {
        case "array":
            switch items {
            case .property(let prop):
                let type = prop.swiftType(for: modelName, propertyName)
                switch type.qualifier {
                case .array:
                    return .builtInArray("[\(type.name)]")
                case .scalar:
                    return .builtInArray("\(type.name)")
                default:
                    fatalError("\(modelName): unsupported q=\(type.qualifier) for array \(propertyName)")
                }
            case .ref(let ref):
                let type = ref.swiftType(qualifier: .array)
                return .customArray(type.name)
            case .none:
                fatalError("\(modelName): array \(propertyName) has no items")
            }

        case "number":
            switch format {
            case .none, "double": return .builtInScalar("Double")
            default: fatalError("\(modelName): unknown format \(String(describing: format)) for number property")
            }

        case "object":
            if let additionalProperties = self.additionalProperties {
                switch additionalProperties {
                case .property(let prop):
                    let inner = prop.rawSwiftType(for: modelName, propertyName)
                    switch inner {
                    case .builtInScalar(let type):
                        return .builtInDictionary("[String: \(type)]")
                    case .builtInArray(let type):
                        return .builtInDictionary("[String: [\(type)]]")
                    case .builtInDictionary(let type):
                        fatalError("\(modelName): \(propertyName) has unsupported type 'dict of \(type)'")
                    case .custom(let type):
                        return .custom(type)
                    case .customArray(let type):
                        return .customArray(type)
                    case .anyCodable:
                        return .anyCodable
                    }
                case .ref(let ref):
                    let refType = ref.swiftType()
                    return .builtInDictionary("[String: \(refType.propertyType)]")
                }
            } else {
                return .anyCodable
            }

        case "string":
            switch format {
            case .none: return .builtInScalar("String")
            case "date-time": return .builtInScalar("Date")
            default: fatalError("\(modelName): unknown string format '\(format!)' for \(propertyName)")
            }

        case "boolean":
            return .builtInScalar("Bool")

        case "integer":
            return .builtInScalar("Int")

        case "double":
            return .builtInScalar("Double")

        default:
            fatalError("\(modelName): unknown type \(type)")
        }
    }
}
