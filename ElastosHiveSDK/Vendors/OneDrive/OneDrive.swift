import Foundation
import Unirest

internal class OneDrive: HiveDriveHandle {
    private static var oneDriveInstance: OneDrive?
    var authHeperHandle: OneDriveAuthHelper
    var driveId: String?

    private init(_ param: OneDriveParameters) {
        authHeperHandle = OneDriveAuthHelper(param.clientId!, param.scopes!, param.redirectUrl!)
    }

    public static func createInstance(_ param: OneDriveParameters) {
        if oneDriveInstance == nil {
            let drive: OneDrive = OneDrive(param)
            oneDriveInstance = drive as OneDrive
        }
    }

    public static func sharedInstance() -> HiveDriveHandle? {
        return oneDriveInstance
    }

    override func driveType() -> DriveType {
        return .oneDrive
    }

    override func login(_ hiveError: @escaping (LoginHandle)) {
        authHeperHandle.login({ (error) in
            try? self.validateDrive()
            hiveError(error)
        })
    }

    override func rootDirectoryHandle(withResult resultHandler: @escaping HiveFileObjectCreationResponseHandler) throws {
        authHeperHandle.checkExpired { (error) in
            let accesstoken = HelperMethods.getkeychain(ACCESS_TOKEN, ONEDRIVE_ACCOUNT) ?? ""
            UNIRest.get({ (request) in
                request?.url = RESTAPI_URL + ROOT_DIR
                request?.headers = ["Content-Type": "application/json;charset=UTF-8", HEADER_AUTHORIZATION: "bearer \(accesstoken)"]
            })?.asJsonAsync({ (response, error) in
                if response?.code != 200 {
                    resultHandler(nil, .jsonFailue(des: (response?.body.jsonObject())!))
                    return
                }
                let jsonData = response?.body.jsonObject() as? Dictionary<String, Any>
                if jsonData == nil || jsonData!.isEmpty {
                    resultHandler(nil, nil)
                }
                let driveFile: OneDriveFile = OneDriveFile()
                driveFile.drive = self
                let folder = response?.body.jsonObject()["folder"]
                if folder != nil {
                    driveFile.isDirectory = true
                    driveFile.isFile = false
                }
                driveFile.createdDateTime = (jsonData!["createdDateTime"] as? String)
                driveFile.lastModifiedDateTime = (jsonData!["lastModifiedDateTime"] as! String)
                driveFile.fileSystemInfo = (jsonData!["fileSystemInfo"] as? Dictionary)
                driveFile.id = (jsonData!["id"] as? String)
                let sub = jsonData!["parentReference"] as? NSDictionary
                if (sub != nil) {
                    driveFile.driveId = (sub!["driveId"] as? String)
                    driveFile.parentId = (sub!["id"] as? String)
                }
                let fullPath = sub!["path"]
                if (fullPath != nil) {
                    let full = fullPath as!String
                    let end = full.index(full.endIndex, offsetBy: -1)
                    driveFile.parentPath = String(full[..<end])
                }
                driveFile.pathName =  "/"
                driveFile.oneDrive = self
                resultHandler(driveFile, nil)
            })
        }
    }

    override func createDirectory(atPath: String, withResult: @escaping HiveFileObjectCreationResponseHandler) throws {
        let accesstoken = HelperMethods.getkeychain(ACCESS_TOKEN, ONEDRIVE_ACCOUNT) ?? ""
        let params: Dictionary<String, Any> = ["name": "New Folder",
                                               "folder": [: ],
                                               "@microsoft.graph.conflictBehavior": "rename"]
        UNIRest.postEntity { (request) in
            request?.url = "\(RESTAPI_URL)/items/\(atPath)/children"
            request?.headers = ["Content-Type": "application/json;charset=UTF-8", HEADER_AUTHORIZATION: "bearer \(accesstoken)"]
            request?.body = try? JSONSerialization.data(withJSONObject: params)
            }?.asJsonAsync({ (response, error) in
                if response?.code != 201 {
                    withResult(nil, .jsonFailue(des: (response?.body.jsonObject())!))
                    return
                }
                // TODO  judje
                let jsonData = response?.body.jsonObject() as? Dictionary<String, Any>
                if jsonData == nil || jsonData!.isEmpty {
                    withResult(nil, nil)
                }
                let driveFile: OneDriveFile = OneDriveFile()
                driveFile.drive = self
                driveFile.oneDrive = self
                driveFile.pathName =  atPath
                let folder = jsonData!["folder"]
                if folder != nil {
                    driveFile.isDirectory = true
                    driveFile.isFile = false
                }
                driveFile.createdDateTime = (jsonData!["createdDateTime"] as? String)
                driveFile.lastModifiedDateTime = (jsonData!["lastModifiedDateTime"] as? String)
                driveFile.fileSystemInfo = (jsonData!["fileSystemInfo"] as? Dictionary)
                driveFile.id = (jsonData!["id"] as? String)
                let sub = jsonData!["parentReference"] as? NSDictionary
                if (sub != nil) {
                    driveFile.driveId = (sub!["driveId"] as? String)
                    driveFile.parentId = (sub!["id"] as? String)
                }
                let fullPath = sub!["path"]
                if (fullPath != nil) {
                    let full = fullPath as!String
                    let end = full.index(full.endIndex, offsetBy: -1)
                    driveFile.parentPath = String(full[..<end])
                }
                withResult(driveFile, nil)
            })
    }

    override func createFile(atPath: String, withResult resultHandler: @escaping HiveFileObjectCreationResponseHandler) throws {
        let accesstoken = HelperMethods.getkeychain(ACCESS_TOKEN, ONEDRIVE_ACCOUNT) ?? ""
        UNIRest.putEntity { (request) in
            request?.url = "\(RESTAPI_URL)\(ROOT_DIR):/\(atPath):/content"
            request?.headers = ["Content-Type": "application/json;charset=UTF-8", HEADER_AUTHORIZATION: "bearer \(accesstoken)"]
            }?.asJsonAsync({ (response, error) in
                if response?.code != 200 {
                    resultHandler(nil, .jsonFailue(des: (response?.body.jsonObject())!))
                    return
                }
                // TODO  judje
                let oneDriveFile: OneDriveFile = OneDriveFile()
                oneDriveFile.drive = self
                oneDriveFile.oneDrive = self
                oneDriveFile.pathName =  atPath
                resultHandler(oneDriveFile, nil)
            })
    }

    override func getFileHandle(atPath: String, withResult resultHandler: @escaping HiveFileObjectCreationResponseHandler) throws {
        authHeperHandle.checkExpired { (error) in
            let accesstoken = HelperMethods.getkeychain(ACCESS_TOKEN, ONEDRIVE_ACCOUNT) ?? ""
            var url = "\(RESTAPI_URL)\(ROOT_DIR):/\(atPath)"
            if atPath == "/" {
                url = RESTAPI_URL + ROOT_DIR
            }
            UNIRest.get({ (request) in
                request?.url = url
                request?.headers = ["Content-Type": "application/json;charset=UTF-8", HEADER_AUTHORIZATION: "bearer \(accesstoken)"]
            })?.asJsonAsync({ (response, error) in
                if response?.code != 200 {
                    resultHandler(nil, .jsonFailue(des: (response?.body.jsonObject())!))
                    return
                }
                // todo jude
                //            let id = response?.body.jsonObject()["id"]
                //            if id == nil {
                //                resultHandler(nil, .failue(des: "pathname is invalid path"))
                //            }
                let jsonData = response?.body.jsonObject() as? Dictionary<String, Any>
                if jsonData == nil || jsonData!.isEmpty {
                    resultHandler(nil, nil)
                }
                let driveFile: OneDriveFile = OneDriveFile()
                driveFile.drive = self
                driveFile.oneDrive = self
                driveFile.pathName =  atPath
                let folder = jsonData!["folder"]
                if folder != nil {
                    driveFile.isDirectory = true
                    driveFile.isFile = false
                }
                driveFile.createdDateTime = (jsonData!["createdDateTime"] as? String)
                driveFile.lastModifiedDateTime = (jsonData!["lastModifiedDateTime"] as? String)
                driveFile.fileSystemInfo = (jsonData!["fileSystemInfo"] as? Dictionary)
                driveFile.id = (jsonData!["id"] as? String)
                let sub = jsonData!["parentReference"] as? NSDictionary
                if (sub != nil) {
                    driveFile.driveId = (sub!["driveId"] as? String)
                    driveFile.parentId = (sub!["id"] as? String)
                }
                let fullPath = sub!["path"]
                if (fullPath != nil) {
                    let full = fullPath as!String
                    let end = full.index(full.endIndex, offsetBy: -1)
                    driveFile.parentPath = String(full[..<end])
                }
                resultHandler(driveFile, nil)
            })
        }
    }

    private func validateDrive() throws {

        var error: NSError?
        let accesstoken = HelperMethods.getkeychain(ACCESS_TOKEN, ONEDRIVE_ACCOUNT) ?? ""
        let response: UNIHTTPJsonResponse? = UNIRest.get({ (request) in
            request?.url = RESTAPI_URL
            request?.headers = ["Content-Type": "application/json;charset=UTF-8", HEADER_AUTHORIZATION: "bearer \(accesstoken)"]
        })?.asJson(&error)
        guard error == nil else {
            return
        }
        guard response?.code == 200 else {
            return
        }
        driveId = (response?.body.jsonObject()["id"] as! String)
    }
}
