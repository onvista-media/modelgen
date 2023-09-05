//
//  ModelGen.swift
//
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

import Foundation
import ArgumentParser

@main
struct ModelGen: ParsableCommand {
    static let version = "v0.1.4"

    @Option(name: .shortAndLong, help: "name of the input file")
    var input: String = "/Users/gereon/Developer/onvista/modelgen/swagger-bz.json"

    @Option(name: .shortAndLong, help: "name of the output directory")
    var output: String = "/Users/gereon/Developer/onvista/modelgen/output"

    @Option(name: .shortAndLong, help: "list of schemas that are generated as classes, not structs")
    var classSchemas: String?

    mutating func validate() throws {
        guard !input.isEmpty else {
            throw ValidationError("input file must be specified")
        }

        guard !output.isEmpty else {
            throw ValidationError("output directory must be specified")
        }
    }

    mutating func run() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: input))
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: data)

        let modelOutput = output + "/Models"
        let requestOutput = output + "/Requests"
        for dir in [modelOutput, requestOutput] {
            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: dir, isDirectory: &isDir)
            if exists && !isDir.boolValue {
                fatalError("output \(dir) exists but is not a directory")
            }
            if !exists {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            }
        }

        // let filter = "/v1/brokerize/export/renderGenericTable"
        // let filter = "/v1/brokerize/order/{id}/cancel"
        if let paths = spec.paths {
            for (path, requests) in paths { // .filter({ $0.key == filter }) {
                let generator = Generator(spec: spec, classSchemas: classSchemas)
                generator.generate(path: path, requests: requests)

//                print(generator.buffer)

                let data = generator.buffer.data(using: .utf8)!

                let name = requests.first?.value.operationId.uppercasedFirst() ?? ""
                let url = URL(fileURLWithPath: "\(requestOutput)/\(name)Request.swift")
                try data.write(to: url, options: .atomic)
            }
        }

        for name in spec.components.schemas.keys {
            print(name)
            let generator = Generator(spec: spec, classSchemas: classSchemas)
            generator.generate(modelName: name)

            let data = generator.buffer.data(using: .utf8)!
            let url = URL(fileURLWithPath: "\(modelOutput)/\(name).swift")
            try data.write(to: url, options: .atomic)
        }
    }
}
