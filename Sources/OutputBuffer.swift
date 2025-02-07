//
//  OutputBuffer.swift
//  
//
//  Created by Gereon Steffens on 02.05.23.
//

import Foundation

final class OutputBuffer {

    private(set) var buffer = ""
    private var indent = 0

    func reset() {
        buffer = ""
        indent = 0
    }

    func print(_ string: String, terminator: String = "\n") {
        let doIndent = !string.isEmpty && buffer.last == "\n"
        let pad = String(repeating: "    ", count: doIndent ? indent : 0)
        buffer += pad + string + terminator
    }

    func indent<T>(closure: () -> T) -> T {
        indent += 1
        let result = closure()
        indent -= 1
        return result
    }

    func block<T>(_ string: String? = nil, closure: () -> T) -> T {
        if let string {
            print(string + " ", terminator: "")
        }
        print("{")
        let result = indent {
            closure()
        }
        print("}")
        return result
    }

    func comment(_ comment: String?) {
        guard let comment else { return }

        let lines = comment.components(separatedBy: "\n")
        for line in lines {
            print("// \(line)")
        }
    }

}
