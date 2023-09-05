//
//  String+Case.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

extension String {
    func lowercasedFirst() -> String {
        guard !isEmpty else { return "" }

        return self.prefix(1).lowercased() + String(self.suffix(count - 1))
    }

    func uppercasedFirst() -> String {
        guard !isEmpty else { return "" }

        return self.prefix(1).uppercased() + String(self.suffix(count - 1))
    }

    // convert a SNAKE_CASED Kebap-Cased or dotted string into a camelCased version
    // FOO -> foo
    // Foo -> foo
    // FOO_BAR -> fooBar
    // Foo.Bar -> fooBar
    func camelCased() -> String {
        let str = self
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "-", with: "_")

        guard str.contains("_") else {
            if str.uppercased() == str {
                return str.lowercased()
            }
            return str.lowercasedFirst()
        }

        return str.components(separatedBy: "_")
            .map { $0.capitalized }
            .joined()
            .lowercasedFirst()
    }
}
