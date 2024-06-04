//
//  Generator+Request.swift
//  
//
//  Created by Gereon Steffens on 22.08.23.
//

import Foundation

extension Generator {
    func generate(path: String, method: String, request: Request, skipHeader: Bool = false) {
        let name = request.operationId.uppercasedFirst() + "Request"

        if !skipHeader {
            generateFileHeader(modelName: name, schema: nil, import: "Dependencies")
        }

        let (_, successType, _) = successValues(for: request)

        comment(request.operationId + ": " + method.uppercased() + " " + path + " -> " + successType)
        if request.deprecated == true {
            print("@available(*, deprecated)")
        }
        block("public struct \(name)") {
            print("static let path = \"\(path)\"")
            print("public let tags = \(request.tags)")
            print("public let urlRequest: URLRequest")
            print(#"@Dependency(\.jsonEncoder) var jsonEncoder"#)
            print(#"@Dependency(\.jsonDecoder) var jsonDecoder"#)
            print(#"@Dependency(\.httpClient) var httpClient"#)

            var bodyType: SwiftType?
            if let body = request.requestBody, case .ref(let ref) = body.content["application/json"]?.schema {
                bodyType = ref.swiftType()
            }
            if let bodyType {
                print("private let body: \(bodyType.propertyType)")
            }

            print("")
            for enumParam in (request.parameters ?? []).filter({ $0.schema.enumCases != nil }) {
                block("public enum \(SwiftKeywords.safe(enumParam.name.uppercasedFirst())): String") {
                    let sortedCases = Set(enumParam.schema.enumCases ?? []).sorted()
                    for enumCase in sortedCases {
                        print("case \(SwiftKeywords.safe(enumCase))")
                    }
                }
                print("")
            }

            let parameters = (request.parameters ?? [])
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
            generateInit(method: method, request: request, parameters: parameters, bodyType: bodyType)

            print("")
            generateResponseEnum(request: request)

            print("")
            generateExecute(request: request)

            print("")
            generateGet(request: request)

            print("")
            generateResult(request: request)
        }
    }

    private func responseCase(for code: String) -> String {
        switch code {
        case "200", "default", "204": return "ok"
        case "201": return "created"
        case "400": return "badRequest"
        case "401": return "unauthorized"
        case "404": return "notFound"
        case "403": return "forbidden"
        case "409": return "conflict"
        case "422": return "unprocessable"
        case "428": return "preconditionRequired"
        case "429": return "tooManyRequests"
        case "500": return "serverError"
        case "503": return "serviceUnavailable"
        case "504": return "gatewayTimeout"
        default: return "_\(code)"
        }
    }

    private func generateInit(method: String, request: Request, parameters: [Parameter], bodyType: SwiftType?) {
        var params = parameters.map {
            ($0.name.camelCased(), $0.schema.swiftType(for: "", $0.name, $0.required == true))
        }

        if let bodyType {
            params.append(("body", bodyType))
        }

        var initParameters = params.map { $0.camelCased() + ": " + $1.propertyType }
        initParameters.append("useCache: Bool = true")

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
                    if type.qualifier == .array && type.isOptional {
                        print(#"queryItems.append(contentsOf: (\#(param.name.camelCased()) ?? []).map { URLQueryItem(name: "\#(param.name)", value: $0) })"#)
                    } else if type.qualifier == .array {
                        print(#"queryItems.append(contentsOf: \#(param.name.camelCased()).map { URLQueryItem(name: "\#(param.name)", value: $0) })"#)
                    } else {
                        print(#"queryItems.append(URLQueryItem(name: "\#(param.name)", value: \#(param.name.camelCased())))"#)
                    }
                }
                print("")
            }

            let headerParams = parameters.filter({ $0.in == "header" })
            if !headerParams.isEmpty {
                print("let headers = [")
                indent {
                    for param in headerParams {
                        print(#""\#(param.name)": \#(param.name.camelCased()),"#)
                    }
                }
                print("].compactMapValues { $0 }")
                print("")
            }

            comment("build URL")
            let keyword = queryParams.isEmpty ? "let" : "var"
            print(#"\#(keyword) components = URLComponents(string: path)!"#)
            if !queryParams.isEmpty {
                print("components.queryItems = queryItems.compactMap { $0 }.filter { $0.value != nil }")
            }

            print("")
            comment("build request")
            print("var request = URLRequest(url: components.url!)")
            print(#"request.httpMethod = "\#(method.uppercased())""#)
            if !headerParams.isEmpty {
                block("for (key, value) in headers") {
                    print("request.setValue(value, forHTTPHeaderField: key)")
                }
            }
            print("request.cachePolicy = useCache ? .useProtocolCachePolicy : .reloadIgnoringLocalAndRemoteCacheData")
            print("")
            print("self.urlRequest = request")
            if bodyType != nil {
                print("self.body = body")
            }
        }
    }

    private func generateResponseEnum(request: Request) {
        block("public enum Response") {
            for (code, response) in request.sortedResponses {
                if code == "204" {
                    print("case ok // 204 no content")
                } else if let schema = response.content?["application/json"]?.schema {
                    switch schema {
                    case .ref(let type):
                        print("case \(responseCase(for: code))(\(type.swiftType().name))")
                    case .schema(let schema):
                        let prop = Property(type: schema.type, description: nil, format: nil, items: nil, deprecated: nil, enumCases: nil, additionalProperties: nil)
                        print("case \(responseCase(for: code))(\(prop.swiftType(for: "", "").name))")
                    }
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

    private func generateExecute(request: Request) {
        comment("return decoded response, raw data and HTTP headers")
        block("public func execute() async -> (Response, Data?, HTTPURLResponse?)") {
            print("let data: Data")
            print("let response: HTTPURLResponse")
            block("do") {
                if request.requestBody != nil {
                    print("var urlRequest = self.urlRequest")
                    print("urlRequest.httpBody = try jsonEncoder.encode(body)")
                }
                print("(data, response) = try await httpClient.execute(urlRequest: urlRequest, tags: tags)")
            }
            block("catch") {
                print("return (.error(error), nil, nil)")
            }
            block("do") {
                block("switch response.statusCode") {
                    for (code, response) in request.sortedResponses {
                        if code == "204" {
                            print("case 204: return (.ok, data, response)")
                        } else if let schema = response.content?["application/json"]?.schema {
                            let caseCode = Int(code) ?? 200
                            switch schema {
                            case .ref(let type):
                                let type = type.swiftType().name
                                print("case \(caseCode): return (.\(responseCase(for: code))(try jsonDecoder.decode(\(type).self, from: data)), data, response)")
                            case .schema(let schema):
                                let prop = Property(type: schema.type, description: nil, format: nil, items: nil, deprecated: nil, enumCases: nil, additionalProperties: nil)
                                let type = prop.swiftType(for: "", "").name
                                print("case \(caseCode): return (.\(responseCase(for: code))(try jsonDecoder.decode(\(type).self, from: data)), data, response)")
                            }
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

    private func successValues(for request: Request) -> (code: String, type: String, Response?) {
        var successType = "()"
        var successCode = "200"
        var successResponse = request.responses["default"] ?? request.responses["200"]
        if successResponse == nil {
            for code in ["201", "204"] {
                successResponse = request.responses[code]
                if successResponse != nil {
                    successCode = code
                    break
                }
            }
        }

        if successCode != "204" {
            if let schema = successResponse?.content?["application/json"]?.schema {
                switch schema {
                case .ref(let type):
                    successType = type.swiftType().name
                case .schema(let schema):
                    let prop = Property(type: schema.type, description: nil, format: nil, items: nil, deprecated: nil, enumCases: nil, additionalProperties: nil)
                    successType = prop.swiftType(for: "", "").name
                }
            } else {
                successType = "Data"
            }
        }

        return (successCode, successType, successResponse)
    }

    private func generateGet(request: Request) {
        let (successCode, successType, successResponse) = successValues(for: request)

        comment("return \(successType) or nil")
        block("public func get() async -> \(successType)?") {
            print("let (response, _, _) = await execute()")
            block("switch response") {
                let caseName = responseCase(for: successCode)
                if successResponse == nil {
                    print("case .\(caseName): return ()")
                } else {
                    if successCode == "204" {
                        print("case .\(caseName): return ()")
                    } else {
                        print("case .\(caseName)(let obj): return obj")
                    }
                }
                print("default: return nil")
            }
        }
    }

    private func generateResult(request: Request) {
        let (successCode, successType, successResponse) = successValues(for: request)

        let errorResponses = request.responses
            .filter {
                $0.key != "default" && !$0.key.starts(with: "2")
            }
            .sorted(by: { $0.key < $1.key })

        comment("return Result<\(successType), APIError>")
        block("public func result() async -> Result<\(successType), APIError>") {
            print("let (response, data, urlResponse) = await execute()")

            block("guard let data, let urlResponse else") {
                block("if case .error(let error) = response") {
                    print("return .failure(.urlError(error))")
                }
                print("return .failure(.unexpected)")
            }

            block("switch response") {
                let caseName = responseCase(for: successCode)
                if successResponse == nil {
                    print("case .\(caseName): return .success(())")
                } else {
                    if successCode == "204" {
                        print("case .\(caseName): return .success(())")
                    } else {
                        print("case .\(caseName)(let obj): return .success(obj)")
                    }
                }
                print("case .error(let error): return .failure(.urlError(error))")
                print("case .invalid(let error): return .failure(.invalid(error, urlResponse, data))")
                print("case .undocumented(_, let data): return .failure(.undocumented(urlResponse, data))")
                for (code, response) in errorResponses {
                    if response.content?["application/json"]?.schema != nil {
                        print("case .\(responseCase(for: code))(let errorObj): return .failure(.apiError(urlResponse, errorObj))")
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
