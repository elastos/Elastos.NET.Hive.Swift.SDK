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

public class ScriptingServiceRender: ScriptingService {    
    private var _controller: ScriptingController

    public init(_ serviceEndpoint: ServiceEndpoint) {
        _controller = ScriptingController(serviceEndpoint)
    }
    
    public func registerScript(_ name: String, _ executable: Executable) -> Promise<Void> {
        return registerScript(name, nil, executable, false, false)
    }
    
    public func registerScript(_ name: String, _ condition: Condition, _ executable: Executable) -> Promise<Void> {
        return registerScript(name, condition, executable, false, false)
    }
    
    public func registerScript(_ name: String, _ executable: Executable, _ allowAnonymousUser: Bool, _ allowAnonymousApp: Bool) -> Promise<Void> {
        return registerScript(name, nil, executable, allowAnonymousUser, allowAnonymousApp)
    }
    
    public func registerScript(_ name: String, _ condition: Condition?, _ executable: Executable, _ allowAnonymousUser: Bool, _ allowAnonymousApp: Bool) -> Promise<Void> {
        return Promise<Any>.async().then { [self] _ -> Promise<Void> in
            return Promise<Void> { resolver in
                do {
                    resolver.fulfill(try _controller.registerScript(name, condition, executable, allowAnonymousUser, allowAnonymousApp))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }
    
    public func unregisterScript(_ name: String) -> Promise<Void> {
        return Promise<Any>.async().then { [self] _ -> Promise<Void> in
            return Promise<Void> { resolver in
                do {
                    resolver.fulfill(try _controller.unregisterScript(name))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }
    
    public func callScript<T>(_ name: String, _ params: [String : Any], _ targetDid: String, _ targetAppDid: String, _ resultType: T.Type) -> Promise<T> {
        return Promise<Any>.async().then { [self] _ -> Promise<T> in
            return Promise<T> { resolver in
                do {
                    resolver.fulfill(try _controller.callScript(name, params, targetDid, targetAppDid, resultType))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }

    public func callScriptUrl<T>(_ name: String, _ params: String, _ targetDid: String, _ targetAppDid: String, _ resultType: T.Type) -> Promise<T> {
        return Promise<Any>.async().then { [self] _ -> Promise<T> in
            return Promise<T> { resolver in
                do {
                    resolver.fulfill(try _controller.callScriptUrl(name, params, targetDid, targetAppDid, resultType))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }
    
    public func uploadFile(_ transactionId: String) -> Promise<FileWriter> {
        return Promise<Any>.async().then { [self] _ -> Promise<FileWriter> in
            return Promise<FileWriter> { resolver in
                do {
                    resolver.fulfill(try _controller.uploadFile(transactionId))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }

    public func downloadFile(_ transactionId: String) -> Promise<FileReader> {
        return Promise<Any>.async().then { [self] _ -> Promise<FileReader> in
            return Promise<FileReader> { resolver in
                do {
                    resolver.fulfill(try _controller.downloadFile(transactionId))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }
}