//
//  MockAnalyticsService.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import Foundation
@testable import TransactionsTestTask

class MockAnalyticsService: AnalyticsService {
    
    var trackedEvents: [AnalyticsEvent] = []
    
    func trackEvent(name: String, parameters: [String : String]) {
        let event = AnalyticsEvent(name: name, parameters: parameters, date: Date())
        trackedEvents.append(event)
    }
    
    func getEvents(filterByName name: String?, from startDate: Date?, to endDate: Date?) -> [AnalyticsEvent] {
        return trackedEvents.filter { event in
            let matchesName = name == nil || event.name == name!
            let matchesStartDate = startDate == nil || event.date >= startDate!
            let matchesEndDate = endDate == nil || event.date <= endDate!
            return matchesName && matchesStartDate && matchesEndDate
        }
    }
    
}
