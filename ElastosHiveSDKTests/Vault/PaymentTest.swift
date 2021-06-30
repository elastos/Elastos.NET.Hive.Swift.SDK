
import XCTest
@testable import ElastosHiveSDK
import ElastosDIDSDK

class PaymentTest: XCTestCase {
    private var payment: Payment?
    
    private let planName = "Free"
    private let priceName = "Rookie"
//    private var orderId = "60d6d8b2bd3b68acb5c45e5b" // /newdid测试网
//    private var txid = "d7f35a35764a7c4f58a0698429425a73fa2e364daa30c0e7393857dd5b966b65"
//    private var txid = "bccf93e3ba2b700adbd78458b710e33488e635c4cf5de6a45f435c3d667bed39" // /newdid测试网
    private var orderId = "60daf5f8743e945342b4f98e" // /主网：/eid
    private var txid = "c4bd3f1f8a1321403f7b281c02109cf9ae05a32d76b93f6e354b3994e943037b" // 主网：eid
    func test0_GetPaymentInfo() {
        let lock = XCTestExpectation(description: "wait for test.")
        _ = payment?.getPaymentInfo().done{ info in
            print(info)// ETJqK7o7gBhzypmNJ1MstAHU2q77fo78jg
            let infoStr = try! info.serialize()
            print("info = \(infoStr)")
            let data = infoStr.data(using: String.Encoding.utf8)
            let dict = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : Any] 
            print(dict)
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }
    
    func test1_getPricingPlan() {
        let lock = XCTestExpectation(description: "wait for test.")
        _ = payment?.getPricingPlan(planName).done{ plan in
            print(plan)
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }
    
    func test2_getPaymentVersion() {
        let lock = XCTestExpectation(description: "wait for test.")
        _ = payment?.getPaymentVersion().done{ version in
            print(version)
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }
    
    func test4_placeOrder() {
        let lock = XCTestExpectation(description: "wait for test.")
        _ = payment?.placeOrder(priceName).done{ order_id in
            print(order_id) // 5fbdf4ee46c829dc73a9a3d2
            self.orderId = order_id
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }

    func test5_payOrder() {
        let lock = XCTestExpectation(description: "wait for test.")
        let txids = [txid]
        _ = payment?.payOrder(orderId, txids).done{ result in
            print(result)
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }
    
    func test6_getOrder() {
        let lock = XCTestExpectation(description: "wait for test.")
        _ = payment?.getOrder(orderId).done{ order in
            print(order)
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }
    
    func test7_getAllOrders() {
        let lock = XCTestExpectation(description: "wait for test.")
        _ = payment?.getAllOrders().done{ list in
            print(list)
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }
    
    func test8_getUsingPricePlan() {
        let lock = XCTestExpectation(description: "wait for test.")
        _ = payment?.getUsingPricePlan().done{ plan in
            print(plan)
            lock.fulfill()
        }.catch{ error in
            XCTFail()
            lock.fulfill()
        }
        self.wait(for: [lock], timeout: 1000.0)
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        do {
            Log.setLevel(.Debug)
            user = try AppInstanceFactory.createUser1()
            let lock = XCTestExpectation(description: "wait for test.")
//            user?.client.createVault(user!.userFactoryOpt.ownerDid, user?.userFactoryOpt.provider).done{ vault in
            user?.client.getVault(user!.userFactoryOpt.ownerDid, user?.userFactoryOpt.provider).done{ vault in

                self.payment = (vault.payment)
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

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
