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

extension HiveAPi {
    /**
     * Current backup process status on node side.
     */
    func getState() -> String {
        return self.baseURL + self.apiPath + "/backup/state"
    }
    
    /**
     * Save the database and files data to backup node server from vault node server.
     */
    func saveToNode() -> String {
        return self.baseURL + self.apiPath + "/backup/save_to_node"
    }
    
    /**
     * Restore backup data to vault and replace the exist one.
     */
    func restoreFromNode() -> String {
        return self.baseURL + self.apiPath + "/backup/restore_from_node"
    }
    
    /**
     * Active backup data to vault on backup server side.
     */
    func activeToVault() -> String {
        return self.baseURL + self.apiPath + "/backup/activate_to_vault"
    }
}
