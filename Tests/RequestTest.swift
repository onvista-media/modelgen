//
//  RequestTest.swift
//  
//
//  Created by Gereon Steffens on 03.05.24.
//

import XCTest
@testable import modelgen

final class RequestTest: XCTestCase {
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
    public let tags = ["/status"]
    public let urlRequest: URLRequest
    @Dependency(\.jsonEncoder) var jsonEncoder
    @Dependency(\.jsonDecoder) var jsonDecoder
    @Dependency(\.httpClient) var httpClient

    public init(useCache: Bool = true) {
        let path = Self.path

        // build URL
        let components = URLComponents(string: path)!

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

    func testRequest() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec)
        let req = try XCTUnwrap(spec.paths?["/status"]?["get"])
        generator.generate(path: "/status", method: "GET", request: req, skipHeader: true)
        XCTAssertEqual(String(generator.buffer.dropLast(1)), multiline: expectedOutput)
    }
}
