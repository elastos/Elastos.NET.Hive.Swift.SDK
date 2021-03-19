/*
* Copyright (c) 2020 Elastos Foundation
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

// TODO
public class FilesServiceRender: FilesProtocol {
    var vault: Vault
    
    public init(_ vault: Vault) {
        self.vault = vault
    }
    
    public func download(_ path: String) -> Promise<FileReader> {
        return Promise<FileReader> { resolver in
            resolver.fulfill(false as! FileReader)
        }
    }
    
    public func delete(_ path: String) -> Promise<Bool> {
        return Promise<Bool> { resolver in
            resolver.fulfill(true)
        }
    }
    
    public func move(_ source: String, _ target: String) -> Promise<Bool> {
        return Promise<Bool> { resolver in
            resolver.fulfill(true)
        }
    }
    
    public func copy(_ source: String, _ target: String) -> Promise<Bool> {
        return Promise<Bool> { resolver in
            resolver.fulfill(true)
        }
    }
    
    public func hash(_ path: String) -> Promise<String> {
        return Promise<String> { resolver in
            resolver.fulfill("")
        }
    }
    
    public func list(_ path: String) -> Promise<Array<FileInfo>> {
        return Promise<Array<FileInfo>> { resolver in
            resolver.fulfill([false as! FileInfo])
        }
    }
    
    public func stat(_ path: String) -> Promise<FileInfo> {
        return Promise<FileInfo> { resolver in
            resolver.fulfill(false as! FileInfo)
        }
    }
    
    public func upload(_ path: String) -> Promise<FileWriter> {
        return Promise<FileWriter> { resolver in
            resolver.fulfill(false as! FileWriter)
        }
    }
}
