//
//  Generator+Request.swift
//  
//
//  Created by Gereon Steffens on 22.08.23.
//

import Foundation

extension Generator {
    func foo() {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "asd", value: "foo"))
    }

    func generate(path: String, requests: [String: Request]) {
        for (method, request) in requests {
            let name = request.operationId.uppercasedFirst() + "Request"

            let parameters = (request.parameters ?? [])
                .sorted { $0.name.lowercased() < $1.name.lowercased() }

            block("struct \(name)") {
                print("let path = \"\(path)\"")

                print("")
                comment(method.uppercased() + ": " + request.operationId)
                var params = parameters
                    .map {
                        let name = $0.name.replacingOccurrences(of: "-", with: "_").lowercasedFirst()
                        let type = $0.schema.swiftType(for: "", $0.name, $0.required == true )
                        return name + ": " + type.propertyType
                    }
                if let body = request.requestBody, case .ref(let ref) = body.content["application/json"]?.schema {
                    params.append("body: \(ref.swiftType().name)")
                }

                block("init(\(params.joined(separator: ", ")))") {
                    print("let path = self.path")
                    for param in parameters.filter({ $0.in == "path" }) {
                        indent {
                            print(#".replacingOccurrences(of: "{\#(param.name)}", with: "\(\#(param.name))")"#)
                        }
                    }
                    print("")
                    print("var queryItems = [URLQueryItem]()")
                    for param in parameters.filter({ $0.in == "query" }) {
                        if param.required == true {
                            print(#"queryItems.append(URLQueryItem(name: "\#(param.name)", value: "\(\#(param.name))")"#)
                        } else {
                            block("if let \(param.name)") {
                                print(#"queryItems.append(URLQueryItem(name: "\#(param.name)", value: "\(\#(param.name))")"#)
                            }
                        }
                    }
                    print("")
                    print("var headers = [String: String]()")
                    for param in parameters.filter({ $0.in == "header" }) {
                        let name = param.name.replacingOccurrences(of: "-", with: "_").lowercasedFirst()
                        if param.required == true {
                            print(#"headers["\#(param.name)"] = "\(\#(name))""#)
                        } else {
                            block("if let \(name)") {
                                print(#"headers["\#(param.name)"] = "\(\#(name))""#)
                            }
                        }
                    }
                }
            }

            for param in (request.parameters ?? []) {
                // Swift.print(param.name, param.in, param.schema.type)
            }

            for (code, response) in request.responses {
                let x = response.content?["application/json"]?.schema
                if case .ref(let ref) = response.content?["application/json"]?.schema {
                    // Swift.print(code, ref.swiftType().name)
                }
            }
        }
    }
}
