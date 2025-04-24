//
//  Generator+Config.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

extension Generator {
    enum DeprecationHandling: String {
        case comment
        case annotate
        case `private`
    }

    struct Config {
        let excludes: [String]
        let includes: [String]
        let imports: [String]
        let defaultValues: [String]
        let classSchemas: Set<String>
        let tag: String?
        let sendable: Bool
        let skipHeader: Bool
        let deprecation: DeprecationHandling

        init(
            excludes: [String] = [],
            includes: [String] = [],
            imports: [String] = [],
            defaultValues: [String] = [],
            classSchemas: Set<String> = [],
            tag: String? = nil,
            sendable: Bool = false,
            skipHeader: Bool = false,
            deprecation: DeprecationHandling = .comment
        ) {
            self.excludes = excludes
            self.includes = includes
            self.imports = imports
            self.defaultValues = defaultValues
            self.classSchemas = classSchemas
            self.tag = tag
            self.sendable = sendable
            self.skipHeader = skipHeader
            self.deprecation = deprecation
        }

        func conformances(_ protocols: [String]) -> String {
            var protocols = protocols
            if sendable {
                protocols.append("Sendable")
            }
            if protocols.isEmpty {
                return ""
            } else {
                return ": " + protocols.joined(separator: ", ")
            }
        }

        static let test = Self(skipHeader: true)
    }
}
