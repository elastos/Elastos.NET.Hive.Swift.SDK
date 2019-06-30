import Foundation
@inline(__always) private func TAG() -> String { return "KeyChainStore" }

class KeyChainStore {

    /* restore `token` from keychain */
    class func restoreToken(_ forDrive: DriveType) -> AuthToken? {
        let keychain: KeychainSwift = KeychainSwift()
        let account = keychain.get(forDrive.rawValue)

        guard account != nil else {
            return nil
        }
        let data = account!.data(using: .utf8)!
        let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let json = JSON(dict as Any)

        let token = AuthToken()
        token.accessToken = json["access_token"].stringValue
        token.refreshToken = json["refresh_token"].stringValue
        token.expiredTime = json["expiredTime"].stringValue
        token.expiredIn = json["expiredIn"].int64Value
        return token
    }

    /* restore `authEntry` from keychain */
    class func restoreAuthEntry(_ forDrive: DriveType) -> OAuthEntry? {
        let keychain: KeychainSwift = KeychainSwift()
        let account = keychain.get(forDrive.rawValue)

        guard account != nil else {
            return nil
        }

        let data = account!.data(using: .utf8)!
        let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let json = JSON(dict as Any)

        let client_id = json[KEYCHAIN_KEY.CLIENT_ID.rawValue].stringValue
        let scope = json[KEYCHAIN_KEY.SCOPE.rawValue].stringValue
        let redirectURL = json[KEYCHAIN_KEY.REDIRECTURL.rawValue].stringValue
        let authEntry = OAuthEntry(client_id, scope, redirectURL)
        return authEntry
    }

    /* writeback `token` to keychain in persistence */
    class func writeback(_ token: AuthToken, _ authEntry: OAuthEntry, _ forDrive: DriveType) -> Void {
        let count = [KEYCHAIN_KEY.ACCESS_TOKEN.rawValue: token.accessToken,
                     KEYCHAIN_KEY.REFRESH_TOKEN.rawValue: token.refreshToken,
                     KEYCHAIN_KEY.EXPIRED_TIME.rawValue: Timestamp.getTimeAfter(time: token.expiredIn),
                     KEYCHAIN_KEY.EXPIRES_IN.rawValue: token.expiredIn,
                     KEYCHAIN_KEY.REDIRECTURL.rawValue: authEntry.redirectURL,
                     KEYCHAIN_KEY.CLIENT_ID.rawValue: authEntry.clientId,
                     KEYCHAIN_KEY.SCOPE.rawValue: authEntry.scope
            ] as [String : Any]
        if !JSONSerialization.isValidJSONObject(count) {
            Log.e(TAG(), "Key-Value is not valid json object")
            return
        }
        let data = try? JSONSerialization.data(withJSONObject: count, options: [])
        let jsonstring = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        guard jsonstring != nil else {
            Log.e(TAG(), "Save Key-Value for account :%s", forDrive.rawValue)
            return
        }
        let keychain = KeychainSwift()
        keychain.set(jsonstring!, forKey: forDrive.rawValue)
    }

    /* removeback `token` to keychain in persistence */
    class func removeback(authEntry: OAuthEntry, forDrive: DriveType) {
        let token = AuthToken()
        token.accessToken = ""
        token.refreshToken = ""
        token.expiredIn = 0
        token.expiredTime = ""
        writeback(token, authEntry, forDrive)
    }

    /* writeback `uid` to keychain in persistence */
    class func writebackForIpfs(_ forDrive: DriveType, _ uid: String) {
        
        let keychain: KeychainSwift = KeychainSwift()
        let account = keychain.get(forDrive.rawValue) ?? ""
        let jsonData:Data = account.data(using: .utf8)!
        let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        let json = JSON(dict as Any)
        let lastUid = json["last_uid"].stringValue
        guard lastUid != uid else {
            return
        }
        // seek
        var uidArry = json["uids"].arrayValue
        let u = uidArry.filter { (item) -> Bool in
            let u = item["uid"].stringValue
            if u == uid{
                return true
            }
            else {
                return false
            }
            }.first
        if u != nil {
            uidArry.append(u!)
        }
        let ipfsJson = ["last_uid": uid, "uids": uidArry] as [String : Any]

        // save
        if !JSONSerialization.isValidJSONObject(ipfsJson) {
            Log.e(TAG(), "Key-Value is not valid json object")
            return
        }
        let data = try? JSONSerialization.data(withJSONObject: ipfsJson, options: [])
        let jsonstring = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        guard jsonstring != nil else {
            Log.e(TAG(), "Save Key-Value for account :%s", forDrive.rawValue)
            return
        }
        keychain.set(jsonstring!, forKey: forDrive.rawValue)
    }

    /* restore `uid` from keychain */
    class func restoreUid(_ account: DriveType) -> String {
        let keychain: KeychainSwift = KeychainSwift()
        let account = keychain.get(account.rawValue)
        guard account != nil else {
            return ""
        }
        let jsonData:Data = account!.data(using: .utf8)!
        let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        let json = JSON(dict as Any)
        let value = json["last_uid"].stringValue
        return value
    }

}
