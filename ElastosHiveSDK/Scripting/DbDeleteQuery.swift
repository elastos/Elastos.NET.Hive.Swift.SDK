/*
* Copyright (c) 2019 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import Foundation

public class DbDeleteQuery: Executable {
    private let TYPE = "delete"
    private var query: Query

    public init(_ name: String, _ collection: String, _ filter: [String: Any]) {
        self.query = Query(collection, filter)
        super.init(TYPE, name)
    }

    func body() -> Query {
        return query
    }
}

public class Query {
    private var collection: String
    private var filter: [String: Any]

    public init(_ collection: String, _ query: [String: Any]) {
        self.collection = collection
        self.filter = query
    }

    public func serialize() throws -> String {
        let jsonGenerator = JsonGenerator()

        jsonGenerator.writeStartObject()
        jsonGenerator.writeStringField("collection", collection)
        let data = try JSONSerialization.data(withJSONObject: filter, options: [])
        guard let jsonString = String(data: data, encoding: .utf8) else {
            return ""
        }
        jsonGenerator.writeStringField("filter", jsonString)

        return jsonGenerator.toString()
    }

    public func jsonSerialize()throws -> [String: Any] {

        return ["collection": collection, "filter": filter]
    }
}
