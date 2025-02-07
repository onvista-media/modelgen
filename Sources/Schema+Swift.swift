//
//  Schema+Swift.swift
//  
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

extension Schema {
    func swiftProperties(for modelName: String, parentRequired: [String]? = nil) throws -> [SwiftProperty] {
        guard let properties else {
            return []
        }

        let required = (self.required ?? []) + (parentRequired ?? [])

        return try properties
            .sorted(by: { $0.key < $1.key })
            .map { name, value in
                let required = required.contains(name) == true
                switch value {
                case .property(let prop):
                    let type = try prop.swiftType(for: modelName, name, required)
                    return SwiftProperty(name: name,
                                         type: type,
                                         comment: prop.description,
                                         deprecated: prop.deprecated == true)
                case .ref(let ref):
                    let type = ref.swiftType(required: required)
                    return SwiftProperty(name: name,
                                         type: type)
                }
            }
    }
}
