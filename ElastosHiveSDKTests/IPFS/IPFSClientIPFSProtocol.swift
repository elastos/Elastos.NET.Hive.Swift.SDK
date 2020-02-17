import XCTest
@testable import ElastosHiveSDK

class IPFSClientIFPSProtocolTest: XCTestCase {
    private let STORE_PATH = "fakePath"

    private var client: HiveClientHandle?
    private var ipfsProtocol: IPFSProtocol?

    func testPutData1() {
        _ = ipfsProtocol?.putString("testHello")
        // TODO
    }

    override func setUp() {
        do {
            let options = try IPFSClientOptionsBuilder()
                .appendRpcNode(IPFSRpcNode("127.0.0.1", 12345))
                .withStorePath(using: STORE_PATH)
                .build()

            XCTAssertNotNil(options)
            XCTAssertTrue(options.rpcNodes.count > 0)

            client = try HiveClientHandle.createInstance(withOptions: options)
            XCTAssertNotNil(client)
            XCTAssertFalse(client!.isConnected())

            try client?.connect()
            XCTAssertTrue(client!.isConnected())

            ipfsProtocol = client!.asIPFS()
            XCTAssertNotNil(ipfsProtocol)

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
