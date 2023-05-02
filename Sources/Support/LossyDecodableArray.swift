//
//  LossyDecodableArray.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

struct LossyDecodableArray<Element: Decodable>: Decodable {
    let elements: [Element]

    private struct None: Decodable {}

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements = [Element]()

        while !container.isAtEnd {
            do {
                let element = try container.decode(Element.self)
                elements.append(element)
            } catch {
                _ = try? container.decode(None.self)
            }
        }

        self.elements = elements
    }
}
