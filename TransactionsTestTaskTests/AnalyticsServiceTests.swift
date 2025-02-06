//
//  AnalyticsServiceTests.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import XCTest
@testable import TransactionsTestTask

class AnalyticsServiceTests: XCTestCase {
    
    var analyticsService: AnalyticsServiceImpl!
    
    override func setUp() {
        super.setUp()
        analyticsService = AnalyticsServiceImpl()
    }
    
    override func tearDown() {
        analyticsService = nil
        super.tearDown()
    }
    
    func testTrackEventAddsEvent() {
        // Initially, no events should be tracked.
        let initialEvents = analyticsService.getEvents(filterByName: nil, from: nil, to: nil)
        XCTAssertEqual(initialEvents.count, 0, "Initial events array should be empty")
        
        // When: track an event
        analyticsService.trackEvent(name: "TestEvent", parameters: ["key": "value"])
        
        // Then: the event should be stored.
        let events = analyticsService.getEvents(filterByName: nil, from: nil, to: nil)
        XCTAssertEqual(events.count, 1, "One event should be tracked")
        XCTAssertEqual(events.first?.name, "TestEvent")
        XCTAssertEqual(events.first?.parameters["key"], "value")
    }
    
    func testGetEventsFilterByName() {
        analyticsService.trackEvent(name: "EventA", parameters: [:])
        analyticsService.trackEvent(name: "EventB", parameters: [:])
        analyticsService.trackEvent(name: "EventA", parameters: [:])
        
        let filteredEvents = analyticsService.getEvents(filterByName: "EventA", from: nil, to: nil)
        
        XCTAssertEqual(filteredEvents.count, 2, "There must be 2 events named EventA")
        for event in filteredEvents {
            XCTAssertEqual(event.name, "EventA", "All events must have the name EventA")
        }
    }
    
    func testGetEventsFilterByDateRange() {
        let expectation = self.expectation(description: "Events with different timestamps")
        
        analyticsService.trackEvent(name: "EarlyEvent", parameters: [:])
        
        let startDate = Date()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.analyticsService.trackEvent(name: "MiddleEvent", parameters: [:])
            let midDate = Date()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.analyticsService.trackEvent(name: "LateEvent", parameters: [:])
                
                let filtered = self.analyticsService.getEvents(filterByName: nil, from: startDate, to: midDate)
                
                XCTAssertEqual(filtered.count, 1, "Should return 1 event in the given range")
                XCTAssertEqual(filtered.first?.name, "MiddleEvent", "The event must be MiddleEvent")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testGetEventsFilterByNameAndDate() {
        let expectation = self.expectation(description: "Filter by name and date")
        
        analyticsService.trackEvent(name: "Common", parameters: [:])
        let startDate = Date()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.analyticsService.trackEvent(name: "Unique", parameters: [:])
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.analyticsService.trackEvent(name: "Common", parameters: [:])
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let filtered = self.analyticsService.getEvents(filterByName: "Common", from: startDate, to: nil)
            XCTAssertEqual(filtered.count, 1, "There should only be one event named 'Common' returned after startDate")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
}
