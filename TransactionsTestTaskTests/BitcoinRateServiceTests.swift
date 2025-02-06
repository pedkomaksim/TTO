//
//  BitcoinRateServiceTests.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import XCTest
import Combine
@testable import TransactionsTestTask

class BitcoinRateServiceTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    var analyticsService: MockAnalyticsService!
    var userDefaults: UserDefaults!
    var rateService: BitcoinRateServiceImpl!
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(MockURLProtocol.self)
        
        userDefaults = UserDefaults(suiteName: "BitcoinRateServiceTests")
        userDefaults.removePersistentDomain(forName: "BitcoinRateServiceTests")
        analyticsService = MockAnalyticsService()
        rateService = BitcoinRateServiceImpl(updateInterval: 1000,
                                               analyticsService: analyticsService,
                                               userDefaults: userDefaults)
    }
    
    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        cancellables.removeAll()
        analyticsService = nil
        rateService = nil
        userDefaults = nil
        super.tearDown()
    }
    
    func testSuccessfulFetch() {
        let jsonString = """
        {
            "bpi": {
                "USD": {
                    "rate_float": 50000.0
                }
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        MockURLProtocol.stubData = jsonData
        MockURLProtocol.stubError = nil
        
        let expectation = XCTestExpectation(description: "Receive bitcoin rate")
        var receivedRate: Double?
        
        rateService.bitcoinRatePublisher
            .sink { rate in
                receivedRate = rate
                expectation.fulfill()
            }
            .store(in: &cancellables)
        rateService.updateFetchInterval(1)
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertEqual(receivedRate, 50000.0, "Received bitcoin rate should be 50000.0")
        XCTAssertEqual(rateService.cachedRate, 50000.0, "Cached rate should be updated")
        
        let successEvents = analyticsService.trackedEvents.filter { $0.name == "bitcoin_rate_update" }
        XCTAssertFalse(successEvents.isEmpty, "Should log success event")
        if let event = successEvents.first {
            XCTAssertEqual(event.parameters["rate"], "50000.00")
        }
    }
    
    func testErrorFetchWithCachedRate() {
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)
        MockURLProtocol.stubError = error
        MockURLProtocol.stubData = nil
        
        rateService.cachedRate = 45000.0
        userDefaults.set(45000.0, forKey: "CachedBitcoinRate")
        
        let expectation = XCTestExpectation(description: "Receive cached bitcoin rate on error")
        var receivedRate: Double?
        
        rateService.bitcoinRatePublisher
            .sink { rate in
                receivedRate = rate
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        rateService.updateFetchInterval(1)
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertEqual(receivedRate, 45000.0, "Should return cached rate on error")
        
        let errorEvents = analyticsService.trackedEvents.filter { $0.name == "bitcoin_rate_update_error" }
        XCTAssertFalse(errorEvents.isEmpty, "Should log error event")
        if let event = errorEvents.first {
            XCTAssertEqual(event.parameters["fallback"], "cached")
        }
    }
    
    func testErrorFetchWithoutCachedRate() {
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)
        MockURLProtocol.stubError = error
        MockURLProtocol.stubData = nil
        
        rateService.cachedRate = nil
        userDefaults.removeObject(forKey: "CachedBitcoinRate")
        
        let expectation = XCTestExpectation(description: "Log error event when no cached rate")
        var receivedValue = false
        rateService.bitcoinRatePublisher
            .sink { _ in
                receivedValue = true
            }
            .store(in: &cancellables)
        
        rateService.updateFetchInterval(1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(receivedValue, "No value should be received when no cached rate is available")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        let errorEvents = analyticsService.trackedEvents.filter { $0.name == "bitcoin_rate_update_error" }
        XCTAssertFalse(errorEvents.isEmpty, "Should log error event")
        if let event = errorEvents.first {
            XCTAssertEqual(event.parameters["fallback"], "none")
        }
    }
    
}
