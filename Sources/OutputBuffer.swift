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

    func indent(closure: () -> Void) {
        indent += 1
        closure()
        indent -= 1
    }

    func block(_ string: String? = nil, closure: () -> Void) {
        if let string {
            print(string + " ", terminator: "")
        }
        print("{")
        indent {
            closure()
        }
        print("}")
    }

    func comment(_ comment: String?) {
        guard let comment else { return }

        let lines = comment.components(separatedBy: "\n")
        for line in lines {
            print("// \(line)")
        }
    }

}
