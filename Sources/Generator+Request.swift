//
//  Generator+Request.swift
//  
//
//  Created by Gereon Steffens on 22.08.23.
//

import Foundation

extension Generator {
    func generate(path: String, requests: [String: Request]) {
        for (method, request) in requests {
            let name = request.operationId.uppercasedFirst() + "Request"

            let parameters = (request.parameters ?? [])
                .sorted { $0.name.lowercased() < $1.name.lowercased() }

            var bodyType: SwiftType?
            if let body = request.requestBody, case .ref(let ref) = body.content["application/json"]?.schema {
                bodyType = ref.swiftType()
            }

            block("public struct \(name)") {
                print("static let path = \"\(path)\"")
                print("public let urlRequest: URLRequest")

                print("")
                comment(method.uppercased() + ": " + request.operationId)
                var params = parameters.map {
                    (parameterName(name: $0.name), $0.schema.swiftType(for: "", $0.name, $0.required == true))
                }

                if let bodyType {
                    params.append(("body", bodyType))
                }

                let initParameters = params.map { $0 + ": " + $1.propertyType }

                block("public init(\(initParameters.joined(separator: ", ")))") {
                    print("let path = Self.path")
                    for param in parameters.filter({ $0.in == "path" }) {
                        indent {
                            print(#".replacingOccurrences(of: "{\#(param.name)}", with: "\(\#(param.name))")"#)
                        }
                    }
                    print("")

                    let queryParams = parameters.filter { $0.in == "query" }
                    if !queryParams.isEmpty {
                        print("var queryItems = [URLQueryItem]()")
                        for param in queryParams {
                            let type = param.schema.swiftType(for: "", param.name, param.required == true)
                            if type.isArray {
                                print(#"queryItems.append(contentsOf: \#(param.name).map { URLQueryItem(name: "\#(param.name)", value: $0) })"#)
                            } else {
                                print(#"queryItems.append(URLQueryItem(name: "\#(param.name)", value: \#(param.name))"#)
                            }
                        }
                        print("")
                    }

                    let headerParams = parameters.filter({ $0.in == "header" })
                    if !headerParams.isEmpty {
                        print("let headers = [")
                        indent {
                            for param in headerParams {
                                let name = parameterName(name: param.name)
                                print(#""\#(param.name)": \#(name),"#)
                            }
                        }
                        print("].compactMapValues { $0 }")
                        print("")
                    }

                    comment("build URL")
                    let keyword = queryParams.isEmpty ? "let" : "var"
                    print(#"\#(keyword) components = URLComponents(string: path)!"#)
                    if !queryParams.isEmpty {
                        print("components.queryItems = queryItems")
                    }

                    comment("build request")
                    print("var request = URLRequest(url: components.url!)")
                    print(#"request.httpMethod = "\#(method.uppercased())""#)
                    if request.requestBody != nil {
                        print("request.httpBody = body")
                    }
                    if !headerParams.isEmpty {
                        block("for (key, value) in headers") {
                            print("request.setValue(value, forHTTPHeaderField: key)")
                        }
                    }
                    print("self.urlRequest = request")
                }

                print("")
                let sortedResponses = request.responses.sorted(by: { $0.key < $1.key })
                block("public enum Response") {
                    for (code, response) in sortedResponses {
                        if let schema = response.content?["application/json"]?.schema, case .ref(let type) = schema {
                            print("case \(responseCase(for: code))(\(type.swiftType().name))")
                        } else if code == "204" {
                            print("case ok // 204 no content")
                        }
                    }
                }

                print("")
                block("public func execute() async -> Response") {
                    block("do") {
                        print("let (data, response) = try await URLSession.shared.data(for: urlRequest)")

                        print("guard let response = response as? HTTPURLResponse else { return .invalid }")
                        print("let decoder = JSONDecoder()")
                        block("switch response.statusCode") {
                            for (code, response) in sortedResponses {
                                if let schema = response.content?["application/json"]?.schema, case .ref(let type) = schema {
                                    let type = type.swiftType().name
                                    let caseCode = Int(code) ?? 200
                                    print("case \(caseCode): return .\(responseCase(for: code))(try decoder.decode(\(type.self), from: data))")
                                } else if code == "204" {
                                    print("case 204: return .ok")
                                }
                            }
                            print("default: return .undocumented(response.statusCode, data)")
                        }
                    }
                    block("catch") {
                        print("return .error(error)")
                    }
                }
            }
        }
    }

    private func parameterName(name: String) -> String {
        name
            .replacingOccurrences(of: "-", with: "_")
            .lowercasedFirst()
    }

    private func responseCase(for code: String) -> String {
        switch code {
        case "200", "default": return "ok"
        case "201": return "created"
        case "400": return "badRequest"
        case "401": return "unauthorized"
        case "404": return "notFound"
        case "403": return "forbidden"
        case "409": return "conflict"
        case "422": return "unprocessable"
        case "429": return "tooManyRequests"
        case "500": return "serverError"
        case "503": return "serviceUnavailable"
        case "504": return "gatewayTimeout"
        default: return "_\(code)"
        }
    }
}
