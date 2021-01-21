
import XCTest
@testable import ElastosHiveSDK
import ElastosDIDSDK

public var factory: AppInstanceFactory?
class BackupTest: XCTestCase {
    private var client: HiveClientHandle?
    private var backup: Backup?
    private var manager: Manager?
    func testGetState() {
        let lock = XCTestExpectation(description: "wait for test.")
        backup?.state().done({ stste in
            print(stste)
            lock.fulfill()
        }).catch({ error in
            XCTFail()
            lock.fulfill()
        })
        self.wait(for: [lock], timeout: 1000.0)
    }

    override func setUpWithError() throws {
        do {
            Log.setLevel(.Debug)
            user = try AppInstanceFactory.createUser2()
            let lock = XCTestExpectation(description: "wait for test.")
            
            user!.client.getManager(user!.userFactoryOpt.ownerDid, user?.userFactoryOpt.provider).then { manager -> Promise<Bool> in
                return manager.createBackup()
            }.then { success -> Promise<Backup> in
                return user!.client.getBackup(user!.userFactoryOpt.ownerDid, user?.userFactoryOpt.provider)
            }.done { [self] backup in
                self.backup = (backup )
                lock.fulfill()
            }.catch { error in
                print(error)
                lock.fulfill()
            }
            self.wait(for: [lock], timeout: 100.0)
        } catch {
            XCTFail()
        }
    }
}
