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
    
    let bitcoinRateService: BitcoinService = BitcoinService()
    let coreDataService: CoreDataService
    
    @Published private(set) var balance: Double = 0.0
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var groupedTransactions: [Date: [Transaction]] = [:]
    
    private let navigationHandler: BitcoinDashboardModelNavigationHandler
    private var cancellables = Set<AnyCancellable>()
    
    private var currentOffset = 0
    private let limit = 20
    var isFetchingTransactions = false
    
    init(
        navigationHandler: BitcoinDashboardModelNavigationHandler,
        coreDataService: CoreDataService
    ) {
        self.navigationHandler = navigationHandler
        self.coreDataService = coreDataService
        fetchBalanceAndTransactions()
    }
    
    func fetchBalanceAndTransactions() {
        guard !isFetchingTransactions else { return }
        isFetchingTransactions = true
        
        coreDataService.fetchBalanceAndTransactions(limit: limit, offset: currentOffset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balance, newTransactions in
                guard let self = self else { return }
                
                print("Баланс: \(balance)")
                print("Транзакции: \(newTransactions)")
                self.balance = balance
                if newTransactions.isEmpty {
                    self.isFetchingTransactions = false
                    return
                }
                
                self.transactions.append(contentsOf: newTransactions)
                self.groupTransactionsByDay(self.transactions)
                self.currentOffset += newTransactions.count
                self.isFetchingTransactions = false
            }
            .store(in: &cancellables)
    }
    
    func fetchBalance() {
        coreDataService.fetchBalance()
            .receive(on: DispatchQueue.main)
            .assign(to: &$balance)
    }
    
    func updateBalance(by amount: Double) {
        coreDataService.topUPBalance(by: amount)
        fetchBalance()
        fetchTransactions()
    }
    
    func fetchTransactions() {
        guard !isFetchingTransactions else { return }
        isFetchingTransactions = true
        
        coreDataService.fetchTransactions(limit: limit, offset: currentOffset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTransactions in
                guard let self = self else { return }
                
                if newTransactions.isEmpty {
                    self.isFetchingTransactions = false
                    return
                }
                
                self.transactions.append(contentsOf: newTransactions)
                self.groupTransactionsByDay(self.transactions)
                self.currentOffset += newTransactions.count
                self.isFetchingTransactions = false
            }
            .store(in: &cancellables)
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
    
}

extension BitcoinDashboardModel: TransactionUpdaterDelegate {
    
    func updateTransaction() {
        fetchBalanceAndTransactions()
    }
    
}
