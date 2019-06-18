import Foundation
import PromiseKit
import Alamofire
@inline(__always) private func TAG() -> String { return "OneDriveFile" }

@objc(OneDriveFile)
internal class OneDriveFile: HiveFileHandle {
    var name: String?
    var sessionManager = SessionManager()

    override init(_ info: HiveFileInfo, _ authHelper: AuthHelper) {
        super.init(info, authHelper)
    }

    override func parentPathName() -> String {
        return HelperMethods.prePath(self.pathName)
    }

    override func lastUpdatedInfo() -> HivePromise<HiveFileInfo> {
        return lastUpdatedInfo(handleBy: HiveCallback<HiveFileInfo>())
    }

    
    override func lastUpdatedInfo(handleBy: HiveCallback<HiveFileInfo>) -> HivePromise<HiveFileInfo> {
        let promise = HivePromise<HiveFileInfo> { resolver in
            _ = self.authHelper!.checkExpired().done { result in
                var url = OneDriveURL.API + "/root"
                if self.pathName != "/" {
                    let ecurl = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    url  = OneDriveURL.API + "/root:\(ecurl)"
                }
                Alamofire.request(url, method: .get,
                           parameters: nil,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Acquiring last file info failed: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Acquiring last file info failed: %s", error.localizedDescription)
                            handleBy.runError(error)
                            resolver.reject(error)
                            return
                        }
                        let jsonData = JSON(dataResponse.result.value as Any)
                        let fileId = jsonData["id"].stringValue
                        let fileInfo = HiveFileInfo(fileId)
                        self.lastInfo = fileInfo
                        handleBy.didSucceed(fileInfo)
                        resolver.fulfill(fileInfo)
                        Log.d(TAG(), "Acquiring last file information succeeded: %s", fileInfo.description)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Acquiring last file info failed: %s", error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func moveTo(newPath: String) -> HivePromise<Bool> {
        return moveTo(newPath: newPath, handleBy: HiveCallback<Bool>())
    }

    override func moveTo(newPath: String, handleBy: HiveCallback<Bool>) -> HivePromise<Bool> {
        let promise = HivePromise<Bool>{ resolver in
            _ = self.authHelper!.checkExpired().done { result in
                if self.validatePath(newPath).0 == false {
                    let error = HiveError.failue(des: self.validatePath(newPath).1)
                    resolver.reject(error)
                    handleBy.runError(error)
                    return
                }
                let path = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = "\(OneDriveURL.API)\(ONEDRIVE_ROOTDIR):\(path)"
                let params: Dictionary<String, Any> = [
                    "parentReference": ["path": "/drive/root:" + newPath],
                    "name": self.name!,
                    "@microsoft.graph.conflictBehavior": "fail"]
                Alamofire.request(url, method: .patch,
                                  parameters: params,
                                  encoding: JSONEncoding.default,
                                  headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Moving this file to %s failed.", newPath, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Moving this file to %s failed.", newPath, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        self.pathName = newPath + self.name!
                        resolver.fulfill(true)
                        handleBy.didSucceed(true)
                        Log.d(TAG(), "Moving this file to %s succeeded.", newPath)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Moving this file to %s failed.", newPath, error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func copyTo(newPath: String) -> HivePromise<Bool> {
        return copyTo(newPath: newPath, handleBy: HiveCallback<Bool>())
    }

    override func copyTo(newPath: String, handleBy: HiveCallback<Bool>) -> HivePromise<Bool> {
        let promise = HivePromise<Bool>{ resolver in
            _ = self.authHelper!.checkExpired().done { result in
                if self.validatePath(newPath).0 == false {
                    let error = HiveError.failue(des: self.validatePath(newPath).1)
                    resolver.reject(error)
                    handleBy.runError(error)
                    return
                }
                let path = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                var url = OneDriveURL.API + ONEDRIVE_ROOTDIR + ":" + path + ":/copy"
                if newPath == "/" {
                    url = OneDriveURL.API + ONEDRIVE_ROOTDIR + "/copy"
                }
                let params: Dictionary<String, Any> = [
                    "parentReference" : ["path": "/drive/root:\(newPath)"],
                    "name": self.name as Any,
                    "@microsoft.graph.conflictBehavior": "fail"]
                Alamofire.request(url, method: .post,
                           parameters: params,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Copying this file to %s falied: %s", newPath, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 202 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Copying this file to %s falied: %s", newPath, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let urlString = dataResponse.response?.allHeaderFields["Location"] as? String ?? ""
                        self.pollingCopyresult(urlString, { result in
                            guard result == true else {
                                let error = HiveError.failue(des: "Operation failed")
                                Log.e(TAG(), "Copying this file to %s falied: %s", newPath, error.localizedDescription)
                                resolver.reject(error)
                                handleBy.runError(error)
                                return
                            }
                            resolver.fulfill(true)
                            handleBy.didSucceed(true)
                            Log.d(TAG(), "Copying this file to %s succeeded", newPath)
                        })
                    }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Copying this file to %s falied: %s", newPath, error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func deleteItem() -> HivePromise<Bool> {
        return deleteItem(handleBy: HiveCallback<Bool>())
    }

    override func deleteItem(handleBy: HiveCallback<Bool>) -> HivePromise<Bool> {
        let promise = HivePromise<Bool>{ resolver in
            _ = self.authHelper!.checkExpired().done { result in
                let path = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url: String = "\(OneDriveURL.API)\(ONEDRIVE_ROOTDIR):/\(path)"
                Alamofire.request(url, method: .delete,
                           parameters: nil,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON(completionHandler: { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Deleting the file item falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 204 else{

                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Deleting the file item falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        self.pathName = ""
                        self.drive = nil
                        self.fileId = ""
                        self.lastInfo = nil
                        resolver.fulfill(true)
                        handleBy.didSucceed(true)
                        Log.d(TAG(), "Deleting the file item succeeded")
                    })
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Deleting the file item falied: %s", error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func readData() -> HivePromise<String> {
        return readData(handleBy: HiveCallback<String>())
    }

    override func readData(handleBy: HiveCallback<String>) -> HivePromise<String> {
        let promise = HivePromise<String> { resolver in
            _ = self.authHelper!.checkExpired().done { result in
                let path = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url: String = "\(OneDriveURL.API)\(ONEDRIVE_ROOTDIR):\(path):/content"
                Alamofire.request(url, method: .get,
                                  parameters: nil,
                                  encoding: JSONEncoding.default,
                                  headers: OneDriveHttpHeader.headers())
                    .responseData { dataResponse in
                        guard dataResponse.response?.mimeType == "text/plain" || dataResponse.response?.mimeType == "application/octet-stream" else {
                            let jsonStr = String(data: dataResponse.data!, encoding: .utf8) ?? ""
                            let error = HiveError.failue(des: jsonStr)
                            Log.e(TAG(), "readData falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let jsonStr = String(data: dataResponse.data!, encoding: .utf8) ?? ""
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "readData falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else{
                            let error = HiveError.failue(des: jsonStr)
                            Log.e(TAG(), "readData falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        Log.d(TAG(), "readData succeed")
                        resolver.fulfill(jsonStr)
                        handleBy.didSucceed(jsonStr)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "readData falied: %s", error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func writeData(withData: Data) -> HivePromise<Bool> {
        return writeData(withData: withData, handleBy: HiveCallback<Bool>())
    }

    override func writeData(withData: Data, handleBy: HiveCallback<Bool>) -> HivePromise<Bool> {
        let promise = HivePromise<Bool> { resolver in
            _ = self.authHelper!.checkExpired().done { result in
                let accesstoken = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
                let url = self.fullUrl(self.pathName, "content")
                let headers = ["Authorization": "bearer \(accesstoken)", "Content-Type": "text/plain"]

                Alamofire.upload(withData, to: url,
                                 method: .put,
                                headers: headers)
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "writeData falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 || dataResponse.response?.statusCode == 201 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "writeData falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        Log.d(TAG(), "writeData succeed")
                        resolver.fulfill(true)
                        handleBy.didSucceed(true)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "writeData falied: %s", error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func writeDataWithLarge(withPath: String) -> HivePromise<Bool> {
        return writeDataWithLarge(withPath: withPath, handleBy: HiveCallback<Bool>())
    }

    override func writeDataWithLarge(withPath: String, handleBy: HiveCallback<Bool>) -> HivePromise<Bool> {

        let promise = HivePromise<Bool> { resolver in
            _ = self.authHelper!.checkExpired().done({ (result) in
                let path = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = "\(OneDriveURL.API)\(ONEDRIVE_ROOTDIR):\(path):/createUploadSession"
                let params: Dictionary<String, Any> = ["file": "file",
                                                       "@microsoft.graph.conflictBehavior": "rename"]
                Alamofire.request(url, method: .post,
                                  parameters: params,
                                  encoding: JSONEncoding.default,
                                  headers: (OneDriveHttpHeader.headers()))
                    .responseJSON(completionHandler: { (dataResponse) in
                        switch dataResponse.result {
                        case .success(let re):
                            let jsonData = JSON(re)
                            let uploadUrl = jsonData["uploadUrl"].stringValue
                            self.splitData(withPath, uploadUrl: uploadUrl, { (isSucceed) in
                                if isSucceed == true {
                                    Log.d(TAG(), "writeDataWithLarge succeed")
                                    resolver.fulfill(true)
                                    handleBy.didSucceed(true)
                                }
                                else {
                                    let error = HiveError.failue(des: "Operation failed")
                                    Log.e(TAG(), "writeDataWithLarge falied: %s", error.localizedDescription)
                                    resolver.reject(error)
                                    handleBy.runError(error)
                                }
                            })
                        case .failure(_): break
                        }
                    })
            }).catch({ (err) in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "writeData falied: %s", error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            })
        }
        return promise
    }

    private func splitData(_ path: String, uploadUrl: String, _ uploadResult: @escaping (_ isSucceed: Bool) -> Void) {

        let size: UInt64 = path.getFileSize()
        guard size > 1024 * 1024 else{
            splitData(path, uploadUrl, 0, Int64(size), Int64(size), true, uploadResult)
            return
        }
        splitData(path, uploadUrl, 0, 1024 * 1024, Int64(size), true, uploadResult)
    }

    private func splitData(_ path: String, _ uploadUrl: String, _ offset: Int64, _ length: Int64, _ size: Int64, _ isFirst: Bool, _ uploadResult: @escaping (_ isSucceed: Bool) -> Void) {
        var newOffset = offset + length
        var newLength = 0
        if (size - newOffset) < (1024 * 1024) {
            newLength = Int(size - newOffset)
        }
        else {
            newLength = 1024 * 1024
        }
        if isFirst == true {
            newOffset = 0
        }
        let fileReader = FileHandle.init(forReadingAtPath:path)
        fileReader?.seek(toFileOffset: UInt64(newOffset))
        let newData = (fileReader?.readData(ofLength: newLength))!
        writeLarge(path, newData, uploadUrl, newOffset, Int64(newLength), Int64(size), uploadResult)
    }

    private func writeLarge(_ path: String, _ data: Data,_ uploadUrl: String, _ offset: Int64, _ length: Int64, _ size: Int64, _ uploadResult: @escaping (_ isSucceed: Bool) -> Void) {

        let star = offset
        let end = offset + length - 1
        let accesstoken = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
        let header: Dictionary<String, String> = [
            "Content-Type": "application/json;charset=UTF-8",
            "Authorization": "bearer \(accesstoken)",
            "Content-Length": "\(length)",
            "Content-Range": "bytes \(star)-\(end)/\(size)",
        ]
        print("data===\(data)\noffset==\(offset)\nsize==\(size)\n")
        Alamofire.upload(data, to: uploadUrl, method: .put, headers: header).responseJSON(completionHandler: { (dataResponse) in
            if dataResponse.response?.statusCode == 202 {
                self.splitData(path, uploadUrl, offset, length, size, false, uploadResult)
            } else if dataResponse.response?.statusCode == 201 || dataResponse.response?.statusCode == 200 {
                uploadResult(true)
            }
            else if dataResponse.response?.statusCode == 401 {
                self.authHelper?.checkExpired().done({ (result) in
                    self.writeLarge(path, data, uploadUrl, offset, length, size, uploadResult)
                }).catch({ (error) in
                    uploadResult(false)
                })
            }
            else {
                self.writeLarge(path, data, uploadUrl, offset, length, size, uploadResult)
            }
        })
    }

    override func close() {
        // TODO
    }

    private func pollingCopyresult(_ url: String, _ copyResult: @escaping (_ isSucceed: Bool) -> Void) {
        Alamofire.request(url,
                          method: .get,
                          parameters: nil, encoding: JSONEncoding.default, headers: nil)
            .responseJSON { (dataResponse) in
                let jsonData = JSON(dataResponse.result.value as Any)
                let stat = jsonData["status"].stringValue
                if stat == "completed" {
                    copyResult(true)
                    return
                }else if stat == "failed" {
                    copyResult(false)
                    return
                }else {
                    self.pollingCopyresult(url, copyResult)
                }
        }
    }

    private func validatePath(_ atPath: String) -> (Bool, String) {

        if self.pathName == "/" {
            return (false, "This is root file")
        }
        return (true, "")
    }

    private func fullUrl(_ path: String, _ operation: String) -> String {
        if path == "" || path == "/" {
            return OneDriveURL.API + "/root/\(operation)"
        }
        let ecUrl = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return OneDriveURL.API + "/root:\(ecUrl):/\(operation)"
    }
}
