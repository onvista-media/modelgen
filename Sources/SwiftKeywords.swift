//
//  SwiftKeywords.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

enum SwiftKeywords {
    static func safe(_ name: String) -> String {
        let startsWithDigit = "0" ... "9" ~= name.prefix(1)
        return startsWithDigit || keywords.contains(name) ? "_\(name)" : name
    }

    private static let keywords = Set([
        "Type",
        "Protocol",
        "Result",
        "Any",
        "AnyObject",
        "Self",
        "Error",

        "class",
        "struct",
        "enum",
        "protocol",
        "extension",
        "return",
        "throw",
        "throws",
        "rethrows",
        "public",
        "private",
        "fileprivate",
        "internal",
        "let",
        "var",
        "where",
        "guard",
        "associatedtype",
        "deinit",
        "func",
        "import",
        "inout",
        "operator",
        "static",
        "subscript",
        "typealias",
        "case",
        "break",
        "continue",
        "default",
        "defer",
        "do",
        "else",
        "fallthrough",
        "for",
        "if",
        "in",
        "repeat",
        "switch",
        "where",
        "while",
        "as",
        "catch",
        "false",
        "true",
        "is",
        "nil",
        "super",
        "self"
    ])
}
