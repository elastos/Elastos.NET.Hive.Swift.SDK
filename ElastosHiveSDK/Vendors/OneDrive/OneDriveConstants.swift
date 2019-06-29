import Foundation


enum KEYCHAIN_KEY: String {
    typealias RawValue = String
    case ACCESS_TOKEN   = "access_token"
    case REFRESH_TOKEN  = "refresh_token"
    case EXPIRES_IN     = "expires_in"
    case EXPIRED_TIME   = "expiredTime"
    case REDIRECTURL    = "redirectURL"
    case SCOPE          = "scope"
    case CLIENT_ID      = "client_id"

}

let AUTHORIZATION_TYPE_CODE = "authorization_code"
let ONEDRIVE_ROOTDIR     = "/root"
let TOKEN_INVALID = "The token is invalid, please refresh token"
