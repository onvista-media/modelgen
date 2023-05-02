# ModelGen

An OpenAPI model generator for Swift, written in Swift.

## Rationale

At onvista media, we have been dissatisfied with the existing Swift generator for openapi specs for quite a while now and have finally taken the plunge to write our own version. This implementation is highly opinionated and specific to our particular needs and leaves out a bunch of features that openapi has, simply because we do not currently use them. We do not use a templating system like most other generators do, but generate the output models directly from the parsed schema.

Supported features are:

* generate simple structs and enums from schema specifications that don't use `allOf`
* generate enums with associated values for "base class" specifications that have a `discriminator`
* generate structs for "child classes" that are referred to by such an discriminator
* class hierarchies are implemented via protocols that contain all "parent" properties, and the parent enum as well as all "children" conform to that protocol
* decoding of string-based enums does not fail if a new string value is added
* decoding of arrays of "base class" types does not fail if a new child class type is added
* property and enum case names are transformed into "swifty" names (e.g. snake case `ENTITY_VALUE` becomes `entityValue`). Collisions with swift keywords and identifiers starting with digits are avoided by prefixing with `_`.

See the examples below. 

## Contributing

We are making this code available under the MIT license in the hope that it may be useful to others out there, and are open to PRs that implement missing features or fix bugs while preserving the current output of the generator. At the same time, we will probably make breaking changes to the generated output if and when it suits our in-house needs. Issues simply asking for additional features are unlikely to be worked on, however.

## Building and running

Clone the repo and `cd` to it, then run `swift run modelgen -i <input> -o <outputDir>` with `input` being your openapi spec in JSON format, and `outputDir` the name of the directory where the generator will place its output files, one `.swift` file per schema. Alternatively, use [`mint`](https://github.com/yonaskolb/mint) to run: `mint run onvista-media/modelgen ...`.

We currently support running on macOS 13.

## Examples

Given the spec 

```
{
    "info": {
        "title": "test spec"
    },
    "components": {
        "schemas": {
            "POD" : {
                "type" : "object",
                "required": [ "bool", "ints" ],
                "properties" : {
                    "ref" : {
                        "$ref" : "#/components/schemas/Object"
                    },
                    "bool" : {
                        "type" : "boolean"
                    },
                    "ints" : {
                        "type" : "array",
                        "items" : {
                            "type" : "integer"
                        }
                    },
                    "lossy" : {
                        "type": "array",
                        "items": {
                            "$ref": "#/components/schemas/Foo"
                        }
                    },
                    "string" : {
                        "type" : "string"
                    },
                    "double" : {
                        "type" : "number"
                    }
                }
            }
        }
    }
}
```

the generated model is 

```
public struct POD: Codable {
    public let bool: Bool
    public let double: Double?
    public let ints: [Int]
    public let lossy: [Foo]?
    public let ref: Object?
    public let string: String?

    public init(bool: Bool, double: Double?, ints: [Int], lossy: [Foo]?, ref: Object?, string: String?) {
        self.bool = bool
        self.double = double
        self.ints = ints
        self.lossy = lossy
        self.ref = ref
        self.string = string
    }

    enum CodingKeys: String, CodingKey {
        case bool = "bool"
        case double = "double"
        case ints = "ints"
        case lossy = "lossy"
        case ref = "ref"
        case string = "string"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bool = try container.decode(Bool.self, forKey: .bool)
        self.double = try container.decodeIfPresent(Double.self, forKey: .double)
        self.ints = try container.decode([Int].self, forKey: .ints)
        self.lossy = try container.decodeIfPresent(LossyDecodableArray<Foo>.self, forKey: .lossy)?.elements
        self.ref = try container.decodeIfPresent(Object.self, forKey: .ref)
        self.string = try container.decodeIfPresent(String.self, forKey: .string)
    }
}
```

for further examples, see the various unit tests.

## Dependencies

The generated code may contain references to types that are not included in the output.
These types are `UnknownCaseRepresentable`, `LossyDecodableArray` and `AnyCodable`. Sample implementations for the first two are found in the `Sources/Support` directory of this repo. For `AnyCodable`, we recommend adding `https://github.com/Flight-School/AnyCodable` to your package dependencies.
