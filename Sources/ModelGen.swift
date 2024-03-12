//
//  ModelGen.swift
//
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

import Foundation
import ArgumentParser

@main
struct ModelGen: ParsableCommand {
    static let version = "v0.1.5"

    @Option(name: .shortAndLong, help: "name of the input file")
    var input: String = "~/Developer/onvista/modelgen/swagger.json"

    @Option(name: .shortAndLong, help: "name of the output directory")
    var output: String = "~/Developer/onvista/modelgen/output/Sources"

    @Option(name: .shortAndLong, help: "list of schemas that are generated as classes, not structs")
    var classSchemas: String?

    @Option(name: [.long, .customShort("x")], help: "list of schemas/requests to ignore")
    var exclude: String?

    @Option(name: .long, help: "list of schemas/requests to generate")
    var include: String?

    @Option(name: .shortAndLong, help: "print to stdout instead of creating files")
    var stdout = false

    mutating func validate() throws {
        input = NSString(string: input).expandingTildeInPath
        output = NSString(string: output).expandingTildeInPath
        guard !input.isEmpty else {
            throw ValidationError("input file must be specified")
        }

        guard !output.isEmpty else {
            throw ValidationError("output directory must be specified")
        }
    }

    mutating func run() throws {
        let env = ProcessInfo().environment
        if env["OS_ACTIVITY_DT_MODE"] == "YES" {
            // running from Xcode
            stdout = true
            input = "/Users/gereon/Developer/onvista/modelgen/swagger-bz.json"
            output = "~/Developer/onvista/modelgen/output/Sources"
            exclude = "WriteEntities,ReadUserSession,GetHubRssFeedDpa,GetHubRssFeedOnvista,GetHubRssFeedReuters,QueryWebsocket"
            include = "CreateCancelOrder"
        }

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

        let excludes = (self.exclude ?? "").split(separator: ",").map { String($0) }
        let includes = (self.include ?? "").split(separator: ",").map { String($0) }

        if let paths = spec.paths {
            for (path, requests) in paths {
                for (method, request) in requests {
                    let name = request.operationId.uppercasedFirst()
                    if excludes.contains(name) {
                        continue
                    }
                    if includes.isEmpty || includes.contains(name) {
                        let generator = Generator(spec: spec, classSchemas: classSchemas)
                        generator.generate(path: path, method: method, request: request)

                        try output(generator.buffer, to: "\(requestOutput)/\(name)Request.swift")
                    }
                }
            }
        }

        for name in spec.components.schemas.keys {
            if excludes.contains(name) {
                continue
            }
            if includes.isEmpty || includes.contains(name) {
                let generator = Generator(spec: spec, classSchemas: classSchemas)
                generator.generate(modelName: name)

                try output(generator.buffer, to: "\(modelOutput)/\(name).swift")
            }
        }
    }

    private func output(_ content: String, to name: String) throws {
        if stdout {
            print(content)
        } else {
            let data = content.data(using: .utf8)!

            let url = URL(fileURLWithPath: name)
            try data.write(to: url, options: .atomic)
        }

    }
}
