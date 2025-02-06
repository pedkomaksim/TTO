//
//  BitcoinDashboardModel.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import Combine
import Foundation

protocol BitcoinDashboardModelNavigationHandler: AnyObject {
    
    func showAddTransaction()
}

class BitcoinDashboardModel {
    
    var isFetchingTransactions = false
    
    let bitcoinRateService: BitcoinRateService
    let coreDataService: CoreDataService
    
    @Published private(set) var bitcoinRate: Double = 0.0
    @Published private(set) var balance: Double = 0.0
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var groupedTransactions: [Date: [Transaction]] = [:]
    
    private var currentOffset = 0
    private var allDataLoaded = false
    private var cancellables = Set<AnyCancellable>()
    
    private let navigationHandler: BitcoinDashboardModelNavigationHandler
    private let limit = 20
    
    init(bitcoinRateService: BitcoinRateService,
         navigationHandler: BitcoinDashboardModelNavigationHandler,
         coreDataService: CoreDataService) {
        self.bitcoinRateService = bitcoinRateService
        self.navigationHandler = navigationHandler
        self.coreDataService = coreDataService
        
        setupBindings()
        refreshData()
    }
    
    func refreshData() {
        coreDataService.refreshData()
    }
    
    func loadNextPage() {
        guard !isFetchingTransactions, !allDataLoaded else { return }
        isFetchingTransactions = true
        let offset = currentOffset
        coreDataService.loadNextPage(limit: limit, offset: offset) { [weak self] newTransactions in
            guard let self = self else { return }
            if newTransactions.isEmpty {
                self.allDataLoaded = true 
            } else {
                self.currentOffset += newTransactions.count
            }
            self.isFetchingTransactions = false
        }
    }
    
    func updateBalance(by amount: Double) {
        coreDataService.topUPBalance(by: amount)
    }
    
    func showAddTransaction() {
        navigationHandler.showAddTransaction()
    }
    
    private func groupTransactionsByDay(_ transactions: [Transaction]) {
        let grouped = Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date ?? Date())
        }
        self.groupedTransactions = grouped
    }
    
    private func setupBindings() {
        coreDataService.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newBalance in
                self?.balance = newBalance
            }
            .store(in: &cancellables)
        
        coreDataService.transactionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTransactions in
                guard let self = self else { return }
                self.transactions = newTransactions
                self.groupTransactionsByDay(newTransactions)
            }
            .store(in: &cancellables)
        
        bitcoinRateService.bitcoinRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.bitcoinRate = rate
                print("Bitcoin rate updated: \(rate)")
            }
            .store(in: &cancellables)
    }
}
