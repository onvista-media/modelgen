//
//  UnknownCaseRepresentable.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

public protocol UnknownCaseRepresentable: RawRepresentable, CaseIterable {
    static var unknownCase: Self { get }
}

extension UnknownCaseRepresentable where RawValue: Equatable {
    public init(rawValue: RawValue) {
        let value = Self.allCases.first { $0.rawValue == rawValue }
        self = value ?? Self.unknownCase
    }
}
