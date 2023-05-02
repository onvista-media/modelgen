//
//  AssertEqual+Multiline.swift
//
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

import XCTest

func XCTAssertEqual(
    _ text: String,
    multiline reference: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    if text == reference {
        return
    }

    let textLines = text.split(separator: "\n", omittingEmptySubsequences: false)
    let referenceLines = reference.split(separator: "\n", omittingEmptySubsequences: false)
    let (diffLine, str1, str2) = firstDiff(textLines, referenceLines)

    XCTAssertEqual(
        text,
        reference,
        #"\#nfirst difference encountered in line \#(diffLine + 1), "\#(str1)" != "\#(str2)""#,
        file: file,
        line: line)
}

private func firstDiff(_ text: [String.SubSequence], _ reference: [String.SubSequence]) -> (Int, String.SubSequence, String.SubSequence) {
    for line in 0..<max(text.count, reference.count) {
        let s1 = text[safe: line]
        let s2 = reference[safe: line]

        switch (s1, s2) {
        case (.some(let str1), .some(let str2)):
            if str1 != str2 {
                return (line, str1, str2)
            }
        case (.some(let str1), .none):
            return (line, str1, "")
        case (.none, .some(let str2)):
            return (line, "", str2)
        default:
            return (line, "", "")
        }
    }
    fatalError("this can't happen")
}

fileprivate extension Array {
    subscript(safe index: Index) -> Element? {
        return index < count ? self[index] : nil
    }
}
