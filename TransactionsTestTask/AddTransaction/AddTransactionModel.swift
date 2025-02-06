//
//  AddTransactionModel.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import Combine
import Foundation

protocol AddTransactionModelNavigationHandler: AnyObject {
    
    //    func showMailFlow()
    
}

final class AddTransactionModel {
    
    let coreDataService: CoreDataService
    
    private var cancellables = Set<AnyCancellable>()
    
    private let navigationHandler: AddTransactionModelNavigationHandler
    
    init(
        navigationHandler: AddTransactionModelNavigationHandler,
        coreDataService: CoreDataService
    ) {
        self.navigationHandler = navigationHandler
        self.coreDataService = coreDataService
    }
    
    func addTransaction(
        amount: Double,
        category: String,
        date: Date
    ) {
        coreDataService.addTransaction(
            amount: -amount,
            category: category,
            date: date
        )
    }
    
}
