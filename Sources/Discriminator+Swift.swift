//
//  Discriminator+Swift.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
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
                return DiscriminatorCase(enumCase: $0.camelCased(), mappedModel: model, rawString: $0)
            }
    }
}
