//
//  BitcoinDashboardModel.swift
//  TestTask
//
//  Created by Максим Педько on 04.02.2025.
//

import Combine
import Foundation

protocol BitcoinDashboardModelNavigationHandler: AnyObject {
    
    //    func showMailFlow()
    
}

final class BitcoinDashboardModel {
    
    let bitcoinRateService: BitcoinRateService = BitcoinRateService()
    let coreDataService: CoreDataService
    
    @Published private(set) var balance: Double = 0.0
    
    private let navigationHandler: BitcoinDashboardModelNavigationHandler
    
    init(
        navigationHandler: BitcoinDashboardModelNavigationHandler,
        coreDataService: CoreDataService
    ) {
        self.navigationHandler = navigationHandler
        self.coreDataService = coreDataService
        coreDataBinding()
    }
    
    
    func coreDataBinding() {
        coreDataService.fetchBalance()
            .receive(on: DispatchQueue.main)
            .assign(to: &$balance)
    }
    
    
}
