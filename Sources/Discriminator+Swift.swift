//
//  Discriminator+Swift.swift
//
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

struct DiscriminatorCase {
    let enumCase: String
    let mappedModel: String
    let rawString: String
}

extension Discriminator {
    var swiftCases: [DiscriminatorCase] {
        mapping
            .sorted(by: { $0.key < $1.key })
            .map {
                let model = $1.components(separatedBy: "/").last!
//                let type = SwiftType(name: model, isOptional: false, isCustom: true, isArray: false)
//                return SwiftProperty(name: $0.snakeCased(), type: type)
                return DiscriminatorCase(enumCase: $0.snakeCased(), mappedModel: model, rawString: $0)
            }
    }
}
