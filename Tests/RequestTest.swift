//
//  RequestTest.swift
//  
//
//  Created by Gereon Steffens on 03.05.24.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

@Suite("Request test")
struct RequestTest {
    private let spec = """
{
  "info": {
    "title": "test spec"
  },
  "paths": {
    "/status": {
      "get": {
        "tags": [
          "/status"
        ],
        "operationId": "getStatus",
        "parameters": [ {
          "name": "foo",
          "in": "query",
          "required": true,
          "schema": {
            "type": "string"
          }
        } ],
        "responses": {
          "default": {
            "description": "default response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Status"
                }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "Status": {
        "required": [
          "status"
        ],
        "type": "object",
        "properties": {
          "status": {
            "type": "string"
          }
        }
      }
    }
  }
}
"""

    private let expectedOutput = #"""
// getStatus: GET /status -> Status
public struct GetStatusRequest {
    static let path = "/status"
    public let tags = ["/status", "testTag"]
    public let urlRequest: URLRequest
    @Dependency(\.jsonEncoder) var jsonEncoder
    @Dependency(\.jsonDecoder) var jsonDecoder
    @Dependency(\.httpClient) var httpClient

    public init(foo: String, useCache: Bool = true) {
        let path = Self.path

        var queryItems = [URLQueryItem?]()
        queryItems.append(URLQueryItem(name: "foo", value: foo))

        // build URL
        var components = URLComponents(string: path)!
        components.queryItems = queryItems.compactMap { $0 }.filter { $0.value != nil }

        // build request
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.cachePolicy = useCache ? .useProtocolCachePolicy : .reloadIgnoringLocalAndRemoteCacheData

        self.urlRequest = request
    }

    public enum Response {
        case ok(Status)

        case undocumented(Int, Data)
        case error(Error)
        case invalid(Error)
    }

    // return decoded response, raw data and HTTP headers
    public func execute() async -> (Response, Data?, HTTPURLResponse?) {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await httpClient.execute(urlRequest: urlRequest, tags: tags)
        }
        catch {
            return (.error(error), nil, nil)
        }
        do {
            switch response.statusCode {
                case 200: return (.ok(try jsonDecoder.decode(Status.self, from: data)), data, response)
                default: return (.undocumented(response.statusCode, data), data, response)
            }
        }
        catch {
            return (.invalid(error), data, response)
        }
    }

    // return Status or nil
    public func get() async -> Status? {
        let (response, _, _) = await execute()
        switch response {
            case .ok(let obj): return obj
            default: return nil
        }
    }

    // return Result<Status, APIError>
    public func result() async -> Result<Status, APIError> {
        let (response, data, urlResponse) = await execute()
        guard let data, let urlResponse else {
            if case .error(let error) = response {
                return .failure(.urlError(error))
            }
            return .failure(.unexpected)
        }
        switch response {
            case .ok(let obj): return .success(obj)
            case .error(let error): return .failure(.urlError(error))
            case .invalid(let error): return .failure(.invalid(error, urlResponse, data))
            case .undocumented(_, let data): return .failure(.undocumented(urlResponse, data))
        }
    }
}
"""#

    private let expectedOutputWithDefaults = #"""
// getStatus: GET /status -> Status
public struct GetStatusRequest {
    static let path = "/status"
    public let tags = ["/status", "testTag"]
    public let urlRequest: URLRequest
    @Dependency(\.jsonEncoder) var jsonEncoder
    @Dependency(\.jsonDecoder) var jsonDecoder
    @Dependency(\.httpClient) var httpClient

    public init(foo: String = DefaultValues.foo, useCache: Bool = true) {
        let path = Self.path

        var queryItems = [URLQueryItem?]()
        queryItems.append(URLQueryItem(name: "foo", value: foo))

        // build URL
        var components = URLComponents(string: path)!
        components.queryItems = queryItems.compactMap { $0 }.filter { $0.value != nil }

        // build request
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.cachePolicy = useCache ? .useProtocolCachePolicy : .reloadIgnoringLocalAndRemoteCacheData

        self.urlRequest = request
    }

    public enum Response {
        case ok(Status)

        case undocumented(Int, Data)
        case error(Error)
        case invalid(Error)
    }

    // return decoded response, raw data and HTTP headers
    public func execute() async -> (Response, Data?, HTTPURLResponse?) {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await httpClient.execute(urlRequest: urlRequest, tags: tags)
        }
        catch {
            return (.error(error), nil, nil)
        }
        do {
            switch response.statusCode {
                case 200: return (.ok(try jsonDecoder.decode(Status.self, from: data)), data, response)
                default: return (.undocumented(response.statusCode, data), data, response)
            }
        }
        catch {
            return (.invalid(error), data, response)
        }
    }

    // return Status or nil
    public func get() async -> Status? {
        let (response, _, _) = await execute()
        switch response {
            case .ok(let obj): return obj
            default: return nil
        }
    }

    // return Result<Status, APIError>
    public func result() async -> Result<Status, APIError> {
        let (response, data, urlResponse) = await execute()
        guard let data, let urlResponse else {
            if case .error(let error) = response {
                return .failure(.urlError(error))
            }
            return .failure(.unexpected)
        }
        switch response {
            case .ok(let obj): return .success(obj)
            case .error(let error): return .failure(.urlError(error))
            case .invalid(let error): return .failure(.invalid(error, urlResponse, data))
            case .undocumented(_, let data): return .failure(.undocumented(urlResponse, data))
        }
    }
}
"""#

    @Test("test request")
    func testRequest() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .init(tag: "testTag", skipHeader: true))
        let req = try #require(spec.paths?["/status"]?["get"])
        let didGenerate = generator.generate(path: "/status", method: "GET", request: req)
        #expect(didGenerate)
        expectNoDifference(String(generator.buffer.dropLast(1)), expectedOutput)
    }

    @Test("test request with defaults")
    func testRequestWithDefaults() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .init(defaultValues: ["foo"], tag: "testTag", skipHeader: true))
        let req = try #require(spec.paths?["/status"]?["get"])
        let didGenerate = generator.generate(path: "/status", method: "GET", request: req)
        #expect(didGenerate)
        expectNoDifference(String(generator.buffer.dropLast(1)), expectedOutputWithDefaults)
    }

    @Test("test request w/o OK response")
    func testRequestWithoutOKResponse() throws {
        let newSpec = spec.replacingOccurrences(of: "\"default\"", with: "\"500\"")
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: newSpec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .init(defaultValues: ["foo"], tag: "testTag", skipHeader: true))
        let req = try #require(spec.paths?["/status"]?["get"])
        let didGenerate = generator.generate(path: "/status", method: "GET", request: req)
        #expect(!didGenerate)
    }
}
