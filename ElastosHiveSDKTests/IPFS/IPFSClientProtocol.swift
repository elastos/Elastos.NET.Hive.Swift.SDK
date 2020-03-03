import XCTest
@testable import ElastosHiveSDK

class IPFSClientProtocoTest: XCTestCase {
    private let STORE_PATH = "fakePath"
    private let IPADDRS: [String] = ["3.133.166.156", "127.0.0.1", "52.83.165.233", "52.83.238.247"]
    private var client: HiveClientHandle?

    func testAsProtocol() {
        XCTAssertNil(client!.asFiles())
        XCTAssertNil(client!.asKeyValues())
        XCTAssertNotNil(client!.asIPFS())
    }

    override func setUp() {
        do {
            let options = try IPFSClientOptionsBuilder()
                .appendRpcNode(IPFSRpcNode(IPADDRS[0], 5001))
                .appendRpcNode(IPFSRpcNode(IPADDRS[1], 5001))
                .appendRpcNode(IPFSRpcNode(IPADDRS[2], 5001))
                .appendRpcNode(IPFSRpcNode(IPADDRS[3], 5001))
                .withStorePath(using: STORE_PATH)
                .build()

            XCTAssertNotNil(options)
            XCTAssertTrue(options.rpcNodes.count > 0)

            client = try HiveClientHandle.createInstance(withOptions: options)
            XCTAssertNotNil(client)
            XCTAssertFalse(client!.isConnected())
            let lock = XCTestExpectation(description: "wait for test connect.")
            let globalQueue = DispatchQueue.global()
            globalQueue.async {
                do {
                    try self.client?.connect()
                    XCTAssertTrue(self.client!.isConnected())
                    lock.fulfill()
                } catch HiveError.failue {
                    XCTFail()
                } catch {
                    XCTFail()
                }
            }
            self.wait(for: [lock], timeout: 100.0)
            XCTAssertTrue(client!.isConnected())

        } catch HiveError.invalidatedBuilder  {
            XCTFail()
        } catch HiveError.insufficientParameters {
            XCTFail()
        } catch HiveError.failue  {
            XCTFail()
        } catch {
            XCTFail()
        }
    }

    override func tearDown() {
        client?.disconnect()
        client = nil
    }
}
