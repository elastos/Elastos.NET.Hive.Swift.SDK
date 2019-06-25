import Foundation
import PromiseKit
import Alamofire
@inline(__always) private func TAG() -> String { return "OneDriveDirectory" }

class OneDriveDirectory: HiveDirectoryHandle {
    var name: String?

    override init(_ info: HiveDirectoryInfo, _ authHelper: AuthHelper) {
        super.init(info, authHelper)
    }

    override func parentPathName() -> String {
        return HelperMethods.prePath(self.pathName)
    }

    override func lastUpdatedInfo() -> HivePromise<HiveDirectoryInfo> {
        return lastUpdatedInfo(handleBy: HiveCallback<HiveDirectoryInfo>())
    }

    override func lastUpdatedInfo(handleBy: HiveCallback<HiveDirectoryInfo>) -> HivePromise<HiveDirectoryInfo> {
        let promise = HivePromise<HiveDirectoryInfo> { resolver in
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { (result) in
                var url = OneDriveURL.API + "/root"
                if self.pathName != "/" {
                    let ecurl = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    url  = OneDriveURL.API + "/root:\(ecurl)"
                }
                Alamofire.request(url, method: .get, parameters: nil,
                                encoding: JSONEncoding.default,
                                 headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Acquiring directory last info falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Acquiring directory last info falied: %s", error.localizedDescription)
                            handleBy.runError(error)
                            resolver.reject(error)
                            return
                        }
                        let jsonData = JSON(dataResponse.result.value as Any)
                        let dirId = jsonData["id"].stringValue
                        let dic = [HiveDirectoryInfo.itemId: dirId]
                        let directoryInfo = HiveDirectoryInfo(dic)
                        self.lastInfo = directoryInfo
                        handleBy.didSucceed(directoryInfo)
                        resolver.fulfill(directoryInfo)
                        Log.e(TAG(), "Acquire directory last info succeeded: %s", directoryInfo.description)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Acquiring directory last info falied: %s", error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func createDirectory(withName: String) -> HivePromise<HiveDirectoryHandle> {
        return createDirectory(withName: withName, handleBy: HiveCallback<HiveDirectoryHandle>())
    }

    override func createDirectory(withName: String, handleBy: HiveCallback<HiveDirectoryHandle>) ->
        HivePromise<HiveDirectoryHandle> {
        let promise = HivePromise<HiveDirectoryHandle> { resolver in
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
                let params: Dictionary<String, Any> = [
                    "name": withName,
                    "folder": [: ],
                    "@microsoft.graph.conflictBehavior": "fail"]
                var url = OneDriveURL.API + "/root/children"
                if self.pathName != "/" {
                    let ecUrl = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    url = OneDriveURL.API + "/root:\(ecUrl):/children"
                }
                Alamofire.request(url, method: .post,
                            parameters: params,
                              encoding: JSONEncoding.default,
                               headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Creating directory %s failed: %s", withName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 201 else{

                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Creating directory %s failed: %s", withName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let jsonData = JSON(dataResponse.result.value as Any)
                        let dirId = jsonData["id"].stringValue
                        let dic = [HiveDirectoryInfo.itemId: dirId]
                        let dirInfo = HiveDirectoryInfo(dic)
                        let dirHandle = OneDriveDirectory(dirInfo, self.authHelper)
                        dirHandle.name = jsonData["name"].string
                        var path = self.pathName + "/" + withName
                        if self.pathName ==  "/" {
                            path = self.pathName + withName
                        }
                        dirHandle.pathName = path
                        dirHandle.lastInfo = dirInfo
                        dirHandle.drive = self.drive

                        handleBy.didSucceed(dirHandle)
                        resolver.fulfill(dirHandle)

                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Creating directory %s failed: %s", withName, error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func directoryHandle(atName: String) -> HivePromise<HiveDirectoryHandle> {
        return directoryHandle(atName: atName, handleBy: HiveCallback<HiveDirectoryHandle>())
    }

    override func directoryHandle(atName: String, handleBy: HiveCallback<HiveDirectoryHandle>) ->
        HivePromise<HiveDirectoryHandle> {
        let promise = HivePromise<HiveDirectoryHandle> { resolver in
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
                var path = self.pathName + "/" + atName
                if self.pathName == "/" {
                    path = self.pathName + atName
                }
                let ecUrl = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = OneDriveURL.API + "/root:\(ecUrl)"
                Alamofire.request(url, method: .get,
                           parameters: nil,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Acquiring subdirectory %s handle falied: %s", atName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else {
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Acquiring subdirectory %s handle falied: %s", atName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let jsonData = JSON(dataResponse.result.value as Any)
                        let dirId = jsonData["id"].stringValue
                        let dic = [HiveDirectoryInfo.itemId: dirId]
                        let dirInfo = HiveDirectoryInfo(dic)
                        let dirHandle = OneDriveDirectory(dirInfo, self.authHelper)
                        dirHandle.name = jsonData["name"].string
                        dirHandle.pathName = path
                        dirHandle.lastInfo = dirInfo
                        dirHandle.drive = self.drive

                        handleBy.didSucceed(dirHandle)
                        resolver.fulfill(dirHandle)

                        Log.d(TAG(), "Acquire subdirectory %s handle succeeded.", atName)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Acquiring subdirectory %s handle falied: %s", atName, error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func createFile(withName: String) -> HivePromise<HiveFileHandle> {
        return createFile(withName: withName, handleBy: HiveCallback<HiveFileHandle>())
    }

    override func createFile(withName: String, handleBy: HiveCallback<HiveFileHandle>) -> HivePromise<HiveFileHandle> {
        let promise = HivePromise<HiveFileHandle> { resolver in
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
                var path = self.pathName + "/" + withName
                if self.pathName == "/" {
                    path = self.pathName + withName
                }
                let ecUrl = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = OneDriveURL.API + "/root:\(ecUrl):/content"
                let params = ["@microsoft.graph.conflictBehavior": "fail"]
                Alamofire.request(url, method: .put,
                           parameters: params,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Creating file %s falied: %s", withName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 201 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Creating file %s falied: %s", withName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let jsonData = JSON(dataResponse.result.value as Any)
                        let fileId = jsonData["id"].stringValue
                        let dic = [HiveFileInfo.itemId: fileId]
                        let fileInfo = HiveFileInfo(dic)
                        let fileHandle = OneDriveFile(fileInfo, self.authHelper)
                        fileHandle.name = jsonData["name"].string
                        fileHandle.pathName = path
                        fileHandle.drive = self.drive
                        fileHandle.lastInfo = fileInfo

                        handleBy.didSucceed(fileHandle)
                        resolver.fulfill(fileHandle)

                        Log.d(TAG(), "Creating a file %s under this directory succeeded", withName)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Creating file %s falied: %s", withName, error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func fileHandle(atName: String) -> HivePromise<HiveFileHandle> {
        return fileHandle(atName: atName, handleBy: HiveCallback<HiveFileHandle>())
    }

    override func fileHandle(atName: String, handleBy: HiveCallback<HiveFileHandle>) ->
        HivePromise<HiveFileHandle> {
        let promise = HivePromise<HiveFileHandle> { resolver in
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
                var path = self.pathName + "/" + atName
                if self.pathName == "/" {
                    path = self.pathName + atName
                }
                let ecUrl = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = OneDriveURL.API + "/root:\(ecUrl)"
                Alamofire.request(url, method: .get,
                           parameters: nil,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Acquiring file %s handle falied: %s", atName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else{

                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Acquiring file %s handle falied: %s", atName, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let jsonData = JSON(dataResponse.result.value as Any)
                        let fileId = jsonData["id"].stringValue
                        let dic = [HiveFileInfo.itemId: fileId]
                        let fileInfo = HiveFileInfo(dic)
                        let fileHandle = OneDriveFile(fileInfo, self.authHelper)
                        fileHandle.name = jsonData["name"].string
                        fileHandle.pathName = path
                        fileHandle.drive = self.drive
                        fileHandle.lastInfo = fileInfo

                        handleBy.didSucceed(fileHandle)
                        resolver.fulfill(fileHandle)

                        Log.d(TAG(), "Acquire file %s handle succeeded.", atName)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Acquiring file %s handle falied: %s", atName, error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func getChildren() -> HivePromise<HiveChildren> {
        return getChildren(handleBy: HiveCallback<HiveChildren>())
    }

    override func getChildren(handleBy: HiveCallback<HiveChildren>) -> HivePromise<HiveChildren> {
        let promise = HivePromise<HiveChildren> { resolver in
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
                let path = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                var url = "\(OneDriveURL.API)/root:\(path):/children"
                if self.pathName == "/" {
                    url = "\(OneDriveURL.API)/root/children"
                }
                Alamofire.request(url, method: .get,
                           parameters: nil,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Acquiring children infos under this directory falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else {
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Acquiring children infos under this directory falied: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let jsonData = JSON(dataResponse.result.value as Any)
                        let children = HiveChildren()
                        // todo
                        children.installValue(jsonData)
                        handleBy.didSucceed(children)
                        resolver.fulfill(children)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Acquiring children infos under this directory falied: %s", error.localizedDescription)
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
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
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
                            Log.e(TAG(), "Moving this directory to %s failed: %s", newPath, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 200 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Moving this directory to %s failed: %s", newPath, error.localizedDescription)
                            self.pathName = newPath + self.name!
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        resolver.fulfill(true)
                        handleBy.didSucceed(true)
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Moving this directory to %s failed: %s", newPath, error.localizedDescription)
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
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
                let path = ("/" + self.pathName).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
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
                            Log.e(TAG(), "Copying this directory to %s falied: %s", newPath, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 202 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Copying this directory to %s falied: %s", newPath, error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        let urlString = dataResponse.response?.allHeaderFields["Location"] as? String ?? ""
                        self.pollingCopyresult(urlString, { result in
                            guard result == true else {
                                let error = HiveError.failue(des: "Operation failed")
                                Log.e(TAG(), "Copying this directory to %s falied: %s", newPath, error.localizedDescription)
                                resolver.reject(error)
                                handleBy.runError(error)
                                return
                            }
                            resolver.fulfill(true)
                            handleBy.didSucceed(true)
                            Log.d(TAG(), "copyTo this directory to %s succeeded", newPath)
                        })
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Copying this directory to %s falied: %s", newPath, error.localizedDescription)
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
            let login = HelperMethods.getKeychain(KEYCHAIN_KEY.ACCESS_TOKEN.rawValue, .ONEDRIVEACOUNT) ?? ""
            guard login != "" else {
                Log.d(TAG(), "Please login first")
                let error = HiveError.failue(des: "Please login first")
                resolver.reject(error)
                handleBy.runError(error)
                return
            }
            _ = self.authHelper.checkExpired().done { result in
                let path = self.pathName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url: String = "\(OneDriveURL.API)\(ONEDRIVE_ROOTDIR):/\(path)"
                Alamofire.request(url, method: .delete,
                           parameters: nil,
                             encoding: JSONEncoding.default,
                              headers: OneDriveHttpHeader.headers())
                    .responseJSON { dataResponse in
                        guard dataResponse.response?.statusCode != 401 else {
                            let error = HiveError.failue(des: TOKEN_INVALID)
                            Log.e(TAG(), "Delete this directory item failed: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        guard dataResponse.response?.statusCode == 204 else{
                            let error = HiveError.failue(des: HelperMethods.jsonToString(dataResponse.data!))
                            Log.e(TAG(), "Delete this directory item failed: %s", error.localizedDescription)
                            resolver.reject(error)
                            handleBy.runError(error)
                            return
                        }
                        self.pathName = ""
                        self.drive = nil
                        self.directoryId = ""
                        self.lastInfo = nil
                        resolver.fulfill(true)
                        handleBy.didSucceed(true)
                        Log.e(TAG(), "Delete the directory item succeeded")
                }
            }.catch { err in
                let error = HiveError.failue(des: err.localizedDescription)
                Log.e(TAG(), "Delete this directory item failed: %s", error.localizedDescription)
                resolver.reject(error)
                handleBy.runError(error)
            }
        }
        return promise
    }

    override func close() {
        // TODO
    }

    private func pollingCopyresult(_ url: String, _ copyResult: @escaping (_ isSucceed: Bool) -> Void) {
        Alamofire.request(url, method: .get,
                          parameters: nil, encoding: JSONEncoding.default, headers: nil)
            .responseJSON { dataResponse in
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

}
