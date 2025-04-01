//
//  Generator+Config.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

extension Generator {
    struct Config {
        let excludes: [String]
        let includes: [String]
        let imports: [String]
        let defaultValues: [String]
        let classSchemas: Set<String>
        let tag: String?
        let sendable: Bool
        let skipHeader: Bool
        let annotateDeprecation: Bool

        init(
            excludes: [String] = [],
            includes: [String] = [],
            imports: [String] = [],
            defaultValues: [String] = [],
            classSchemas: Set<String> = [],
            tag: String? = nil,
            sendable: Bool = false,
            skipHeader: Bool = false,
            annotateDeprecation: Bool = false
        ) {
            self.excludes = excludes
            self.includes = includes
            self.imports = imports
            self.defaultValues = defaultValues
            self.classSchemas = classSchemas
            self.tag = tag
            self.sendable = sendable
            self.skipHeader = skipHeader
            self.annotateDeprecation = annotateDeprecation
        }

        static let test = Self(skipHeader: true)
    }
}
