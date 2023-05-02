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

    func snakeCased() -> String {
        guard self.contains("_") else {
            if self.uppercased() == self {
                return self.lowercased()
            }
            return self.lowercasedFirst()
        }

        return components(separatedBy: "_")
            .map { $0.capitalized }
            .joined()
            .lowercasedFirst()
    }
}
