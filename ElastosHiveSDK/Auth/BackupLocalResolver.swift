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
import ObjectMapper

public class BackupLocalResolver: LocalResolver {
    
    public override func restoreToken() throws -> AuthToken? {
        if self.serviceEndpoint.serviceDid == nil {
            return nil
        }
        
        let tokenStr = self.dataStorage.loadBackupCredential(self.serviceEndpoint.serviceDid!)
        if tokenStr == nil {
            return nil
        }
        
        if let data = tokenStr!.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                return AuthTokenToBackup(JSON: json!)
            } catch {
                throw error
            }
        }
        return nil
    }
    
    
    public override func saveToken(_ token: AuthToken) throws {
        if self.serviceEndpoint.serviceDid != nil {
            self.dataStorage.storeBackupCredential(self.serviceEndpoint.serviceDid!, Mapper().toJSONString(token, prettyPrint: true)!)
        }
    }
    
    public override func clearToken() {
        if self.serviceEndpoint.serviceDid != nil {
            self.dataStorage.clearBackupCredential(self.serviceEndpoint.serviceDid!)
        }
    }

}