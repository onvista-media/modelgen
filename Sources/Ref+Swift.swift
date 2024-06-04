//
//  Ref+Swift.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

extension Ref {
    func swiftType(required: Bool = true, qualifier: SwiftType.CollectionQualifier = .scalar) -> SwiftType {
        assert(ref.starts(with: "#/components/schemas/"))
        let name = ref.components(separatedBy: "/").last!
        return SwiftType(name: name, isOptional: !required, isCustom: true, qualifier: qualifier)
    }
}
