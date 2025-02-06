//
//  CoreDataService.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import CoreData
import Combine

protocol CoreDataService: AnyObject {
    
    var balancePublisher: AnyPublisher<Double, Never> { get }
    var transactionsPublisher: AnyPublisher<[Transaction], Never> { get }
    
    func addTransaction(amount: Double, category: String, date: Date)
    func topUPBalance(by amount: Double)
    func refreshData()
    func loadNextPage(limit: Int, offset: Int, completion: @escaping ([Transaction]) -> Void)
    
}

final class CoreDataServiceImpl: CoreDataService {
    
    @Published private var balance: Double = 0.0
    @Published private var transactions: [Transaction] = []
    
    var balancePublisher: AnyPublisher<Double, Never> {
        $balance.eraseToAnyPublisher()
    }
    
    var transactionsPublisher: AnyPublisher<[Transaction], Never> {
        $transactions.eraseToAnyPublisher()
    }
    
    private let container: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    
    init(modelName: String = "TransactionsTestTask") {
        container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        backgroundContext = container.newBackgroundContext()
        refreshData()
    }
    
    private func fetchBalanceFromStore() {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            let request: NSFetchRequest<Balance> = Balance.fetchRequest()
            if let balanceObj = try? self.backgroundContext.fetch(request).first {
                DispatchQueue.main.async {
                    self.balance = balanceObj.amount
                }
            } else {
                DispatchQueue.main.async {
                    self.balance = 0
                }
            }
        }
    }
    
    private func fetchAllTransactions() {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            if let fetchedTransactions = try? self.backgroundContext.fetch(request) {
                DispatchQueue.main.async {
                    self.transactions = fetchedTransactions
                }
            }
        }
    }
    
    private func saveContext() {
        guard backgroundContext.hasChanges else { return }
        do {
            try backgroundContext.save()
        } catch {
            print("Error saving Core Data context: \(error)")
        }
    }
    
    private func updateBalance(by amount: Double) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            let request: NSFetchRequest<Balance> = Balance.fetchRequest()
            let balanceObj = (try? self.backgroundContext.fetch(request))?.first ?? Balance(context: self.backgroundContext)
            balanceObj.amount += amount
            self.saveContext()
            self.fetchBalanceFromStore()
        }
    }
    
    func addTransaction(amount: Double, category: String, date: Date) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            let transaction = Transaction(context: self.backgroundContext)
            transaction.amount = amount
            transaction.category = category
            transaction.date = date
            
            self.updateBalance(by: amount)
            self.saveContext()
            
            DispatchQueue.main.async {
                self.transactions.insert(transaction, at: 0)
            }
        }
    }
    
    func topUPBalance(by amount: Double) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            let request: NSFetchRequest<Balance> = Balance.fetchRequest()
            let balanceObj = (try? self.backgroundContext.fetch(request))?.first ?? Balance(context: self.backgroundContext)
            balanceObj.amount += amount
            
            let transaction = Transaction(context: self.backgroundContext)
            transaction.amount = amount
            transaction.category = "Top up balance"
            transaction.date = Date()
            
            self.saveContext()
            self.fetchBalanceFromStore()
            
            DispatchQueue.main.async {
                self.transactions.insert(transaction, at: 0)
            }
        }
    }
    
    func refreshData() {
        DispatchQueue.main.async { [weak self] in
            self?.transactions = []
        }
        fetchBalanceFromStore()
        loadNextPage(limit: 20, offset: 0) { _ in }
    }
    
    func loadNextPage(limit: Int, offset: Int, completion: @escaping ([Transaction]) -> Void) {
            backgroundContext.perform { [weak self] in
                guard let self = self else {
                    completion([])
                    return
                }
                let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                request.fetchLimit = limit
                request.fetchOffset = offset
                let fetchedTransactions = (try? self.backgroundContext.fetch(request)) ?? []
                DispatchQueue.main.async {
                    self.transactions.append(contentsOf: fetchedTransactions)
                    completion(fetchedTransactions)
                }
            }
        }
    
}
