import XCTest
import LoggerFactory
@testable import AndroidDeviceReader

final class AndroidDeviceReaderTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
        
        LoggerFactory.append(logWriter: ConsoleLogger())
        LoggerFactory.enable([.info, .warning, .error, .trace])
    }
    
    func testAdbNotExist() throws {
        
        let bridge = Android(path: "/nopath/adb")
        XCTAssertEqual(bridge.isBridgeReady(), false)
    }
    
    func testListFolders() throws {
        let bridge = Android(path: "/Users/kelvinwong/Develop/mac/adb")
        XCTAssertEqual(bridge.isBridgeReady(), true)
        let deviceIds = bridge.devices()
        print(deviceIds.count)
        if deviceIds.count > 0 {
            let deviceId = deviceIds[0]
            if let device = bridge.device(id: deviceId) {
                print(device.represent())
                print(device.manufacture)
                print(device.model)
                print(device.name)
            }
            let folders = bridge.folders(device: deviceId, in: "/sdcard")
            for folder in folders {
                print(folder)
            }
        }
    }
}
