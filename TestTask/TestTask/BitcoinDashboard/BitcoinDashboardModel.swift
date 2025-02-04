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
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var groupedTransactions: [Date: [Transaction]] = [:]
    
    private let navigationHandler: BitcoinDashboardModelNavigationHandler
    private var cancellables = Set<AnyCancellable>()
    
    private var currentOffset = 0
    private let limit = 20
    private var isFetchingTransactions = false
    
    init(
        navigationHandler: BitcoinDashboardModelNavigationHandler,
        coreDataService: CoreDataService
    ) {
        self.navigationHandler = navigationHandler
        self.coreDataService = coreDataService
        coreDataBinding()
        fetchTransactions()
    }
    
    func coreDataBinding() {
        coreDataService.fetchBalance()
            .receive(on: DispatchQueue.main)
            .assign(to: &$balance)
    }
    
    func fetchTransactions() {
        guard !isFetchingTransactions else { return }
        isFetchingTransactions = true
        
        coreDataService.fetchTransactions(limit: limit, offset: currentOffset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTransactions in
                guard let self = self else { return }
                self.transactions.append(contentsOf: newTransactions)
                self.groupTransactionsByDay(self.transactions)
                self.currentOffset += newTransactions.count
                self.isFetchingTransactions = false
            }
            .store(in: &cancellables)
    }
    
    private func groupTransactionsByDay(_ transactions: [Transaction]) {
        let grouped = Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date ?? Date())
        }
        self.groupedTransactions = grouped
    }
    
}
