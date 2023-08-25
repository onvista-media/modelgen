//
//  SwiftProperty.swift
//
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

struct SwiftProperty {
    /// name as in the open api spec
    let specName: String

    /// name as used in the generated source, may use initial `_` to avoid clashes with swift keywords
    let name: String

    let type: SwiftType

    let comment: String?

    let deprecated: Bool

    init(name: String,
         type: SwiftType,
         comment: String? = nil,
         deprecated: Bool = false
    ) {
        self.specName = name
        self.name = SwiftKeywords.safe(name)
        self.type = type
        self.comment = comment
        self.deprecated = deprecated
    }
}

struct SwiftType {
    let name: String
    let isOptional: Bool
    let isCustom: Bool
    let isArray: Bool
    let isAnyCodable: Bool

    init(name: String, isOptional: Bool, isCustom: Bool, isArray: Bool, isAnyCodable: Bool = false) {
        self.name = SwiftKeywords.safe(name)
        self.isOptional = isOptional
        self.isCustom = isCustom
        self.isArray = isArray
        self.isAnyCodable = isAnyCodable
    }

    var propertyType: String {
        let openBracket = (isArray ? "[" : "")
        let closeBracket = (isArray ? "]" : "")
        let optional = (isOptional ? "?" : "")
        return "\(openBracket)\(name)\(closeBracket)\(optional)"
    }

    var baseType: String {
        let openBracket = (isArray ? "[" : "")
        let closeBracket = (isArray ? "]" : "")
        return "\(openBracket)\(name)\(closeBracket)"
    }
}
