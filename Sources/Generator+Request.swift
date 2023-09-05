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

            generateFileHeader(modelName: name, schema: nil, import: "Dependencies")

            let parameters = (request.parameters ?? [])
                .sorted { $0.name.lowercased() < $1.name.lowercased() }

            block("public struct \(name)") {
                print("static let path = \"\(path)\"")
                print("public let urlRequest: URLRequest")
                print(#"@Dependency(\.jsonEncoder) var jsonEncoder"#)
                print(#"@Dependency(\.jsonDecoder) var jsonDecoder"#)
                print(#"@Dependency(\.httpClient) var httpClient"#)

                var bodyType: SwiftType?
                if let body = request.requestBody, case .ref(let ref) = body.content["application/json"]?.schema {
                    bodyType = ref.swiftType()
                }
                if bodyType != nil {
                    print("private var body: \(bodyType!.propertyType)")
                }

                print("")
                comment(method.uppercased() + ": " + request.operationId)

                generateInit(method: method, request: request, parameters: parameters, bodyType: bodyType)

                print("")
                generateResponseEnum(request: request)

                print("")
                generateExecuteRaw(request: request)

                print("")
                generateGet(request: request)

                print("")
                generateExecute(request: request)
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

    private func generateInit(method: String, request: Request, parameters: [Parameter], bodyType: SwiftType?) {
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
                print("var queryItems = [URLQueryItem?]()")
                for param in queryParams {
                    let type = param.schema.swiftType(for: "", param.name, param.required == true)
                    if type.isArray {
                        print(#"queryItems.append(contentsOf: \#(param.name).map { URLQueryItem(name: "\#(param.name)", value: $0) })"#)
                    } else {
                        print(#"queryItems.append(URLQueryItem(name: "\#(param.name)", value: \#(param.name)))"#)
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
                print("components.queryItems = queryItems.compactMap { $0 }")
            }

            comment("build request")
            print("var request = URLRequest(url: components.url!)")
            print(#"request.httpMethod = "\#(method.uppercased())""#)
            if !headerParams.isEmpty {
                block("for (key, value) in headers") {
                    print("request.setValue(value, forHTTPHeaderField: key)")
                }
            }
            print("self.urlRequest = request")
            if bodyType != nil {
                print("self.body = body")
            }
        }
    }

    private func generateResponseEnum(request: Request) {
        block("public enum Response") {
            for (code, response) in request.sortedResponses {
                if let schema = response.content?["application/json"]?.schema, case .ref(let type) = schema {
                    print("case \(responseCase(for: code))(\(type.swiftType().name))")
                } else if code == "204" {
                    print("case ok // 204 no content")
                } else if code == "200" {
                    print("case ok(Data)")
                }
            }
            print("")
            print("case undocumented(Int, Data)")
            print("case error(Error)")
            print("case invalid(Error)")
        }
    }

    private func generateExecuteRaw(request: Request) {
        comment("return decoded response, raw data and HTTP headers")
        block("public func executeRaw() async -> (Response, Data?, HTTPURLResponse?)") {
            print("let data: Data")
            print("let response: HTTPURLResponse")
            block("do") {
                if request.requestBody != nil {
                    print("var urlRequest = self.urlRequest")
                    print("urlRequest.httpBody = try? jsonEncoder.encode(body)")
                }
                print("(data, response) = try await httpClient.execute(urlRequest: urlRequest)")
            }
            block("catch") {
                print("return (.error(error), nil, nil)")
            }
            block("do") {
                block("switch response.statusCode") {
                    for (code, response) in request.sortedResponses {
                        if let schema = response.content?["application/json"]?.schema, case .ref(let type) = schema {
                            let type = type.swiftType().name
                            let caseCode = Int(code) ?? 200
                            print("case \(caseCode): return (.\(responseCase(for: code))(try jsonDecoder.decode(\(type).self, from: data)), data, response)")
                        } else if code == "204" {
                            print("case 204: return (.ok, data, response)")
                        } else if code == "200" {
                            print("case 200: return (.ok(data), data, response)")
                        }
                    }
                    print("default: return (.undocumented(response.statusCode, data), data, response)")
                }
            }
            block("catch") {
                print("return (.invalid(error), data, response)")
            }
        }
    }

    private func generateGet(request: Request) {
        var successType = "()"
        let successResponse = request.responses["default"] ?? request.responses["200"]
        if let schema = successResponse?.content?["application/json"]?.schema, case .ref(let type) = schema {
            successType = type.swiftType().name
        } else if successResponse != nil {
            successType = "Data"
        }
        comment("return \(successType) or nil")
        block("public func get() async -> \(successType)?") {
            print("let (response, _, _) = await executeRaw()")
            block("switch response") {
                if successResponse == nil {
                    print("case .ok: return ()")
                } else {
                    print("case .ok(let obj): return obj")
                }
                print("default: return nil")
            }
        }
    }

    private func generateExecute(request: Request) {
        var successType = "()"
        let successResponse = request.responses["default"] ?? request.responses["200"]
        if let schema = successResponse?.content?["application/json"]?.schema, case .ref(let type) = schema {
            successType = type.swiftType().name
        } else if successResponse != nil {
            successType = "Data"
        }

        var errorType = ""
        let errorResponses = request.responses
            .filter {
                $0.key != "default" && !$0.key.starts(with: "2")
            }
            .sorted(by: { $0.key < $1.key })

        if let schema = errorResponses.first?.value.content?["application/json"]?.schema, case .ref(let type) = schema {
            errorType = type.swiftType().name
        }

        comment("return Result<\(successType), APIError>")
        block("public func execute() async -> Result<\(successType), APIError<\(errorType)>>") {
            print("let (response, data, urlResponse) = await executeRaw()")

            block("guard data != nil, let urlResponse else") {
                block("if case .error(let error) = response") {
                    print("return .failure(.urlError(error))")
                }
                print("return .failure(.unexpected)")
            }

            block("switch response") {
                if successResponse == nil {
                    print("case .ok: return .success(())")
                } else {
                    print("case .ok(let obj): return .success(obj)")
                }
                print("case .error(let error): return .failure(.urlError(error))")
                print("case .invalid(let error): return .failure(.invalid(error))")
                print("case .undocumented(_, let data): return .failure(.undocumented(urlResponse, data))")
                for (code, response) in errorResponses {
                    if response.content?["application/json"]?.schema != nil {
                        print("case .\(responseCase(for: code))(let errorObj): return .failure(.apiError(urlResponse, errorObj)) // x")
                    }
                }
            }
        }
    }
}

extension Request {
    var sortedResponses: [(String, Response)] {
        self.responses.sorted(by: { $0.key < $1.key })
    }
}
