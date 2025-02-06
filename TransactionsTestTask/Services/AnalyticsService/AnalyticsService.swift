//
//  AnalyticsService.swift
//  TransactionsTestTask
//
//

import Foundation

/// Analytics Service is used for events logging
/// The list of reasonable events is up to you
/// It should be possible not only to track events but to get it from the service
/// The minimal needed filters are: event name and date range
/// The service should be covered by unit tests

protocol AnalyticsService: AnyObject {
    
    func trackEvent(name: String, parameters: [String: String])
    func getEvents(filterByName name: String?, from startDate: Date?, to endDate: Date?) -> [AnalyticsEvent]

}

final class AnalyticsServiceImpl {
    
    private var events: [AnalyticsEvent] = []
    
    init() { }
}

extension AnalyticsServiceImpl: AnalyticsService {
    
    func trackEvent(name: String, parameters: [String: String]) {
        
        let event = AnalyticsEvent(
            name: name,
            parameters: parameters,
            date: Date()
        )
        
        events.append(event)
        print("Analytics event tracked: \(name), parameters: \(parameters)")
    }
    
    func getEvents(filterByName name: String? = nil,
                       from startDate: Date? = nil,
                       to endDate: Date? = nil) -> [AnalyticsEvent] {
            return events.filter { event in
                let matchesName = name == nil || event.name == name!
                let matchesStartDate = startDate == nil || event.date >= startDate!
                let matchesEndDate = endDate == nil || event.date <= endDate!
                return matchesName && matchesStartDate && matchesEndDate
            }
        }
}
