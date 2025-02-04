//
//  CoreDataService.swift
//  TestTask
//
//  Created by Максим Педько on 04.02.2025.
//

import CoreData
import Combine

class CoreDataService {
    
    static let shared = CoreDataService()
    
    private let container: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        container = NSPersistentContainer(name: "TestTask")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        backgroundContext = container.newBackgroundContext()
    }
    
    func fetchBalance() -> AnyPublisher<Double, Never> {
        Future { [weak self] promise in
            self?.backgroundContext.perform {
                let request: NSFetchRequest<Balance> = Balance.fetchRequest()
                if let balance = (try? self?.backgroundContext.fetch(request))?.first {
                    promise(.success(balance.amount))
                } else {
                    promise(.success(0))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateBalance(by amount: Double) {
        backgroundContext.perform { [weak self] in
            let request: NSFetchRequest<Balance> = Balance.fetchRequest()
            let balance = (try? self?.backgroundContext.fetch(request))?.first ?? Balance(context: self!.backgroundContext)
            balance.amount += amount
            self?.saveContext()
        }
    }
    
    func addTransaction(amount: Double, category: String, date: Date) {
        backgroundContext.perform { [weak self] in
            let transaction = Transaction(context: self!.backgroundContext)
            transaction.amount = amount
            transaction.category = category
            transaction.date = date
            self?.updateBalance(by: -amount)
            self?.saveContext()
        }
    }
    
    func fetchTransactions(limit: Int, offset: Int) -> AnyPublisher<[Transaction], Never> {
        Future { [weak self] promise in
            self?.backgroundContext.perform {
                let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                request.fetchLimit = limit
                request.fetchOffset = offset
                let transactions = (try? self?.backgroundContext.fetch(request)) ?? []
                promise(.success(transactions))
            }
        }.eraseToAnyPublisher()
    }
    
    private func saveContext() {
        guard backgroundContext.hasChanges else { return }
        do {
            try backgroundContext.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
    
}

extension CoreDataService {
    // DTO
    func seedTransactions() {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let transactions: [(Double, String, Date)] = [
                (-0.1, "Food", Date()),
                (-0.2, "Entertainment", Date().addingTimeInterval(-86400)), // Вчера
                (-0.05, "Transport", Date().addingTimeInterval(-172800)) // Позавчера
            ]
            
            for (amount, category, date) in transactions {
                let transaction = Transaction(context: self.backgroundContext)
                transaction.amount = amount
                transaction.category = category
                transaction.date = date
            }
            
            self.saveContext()
            print("Seeded test transactions")
        }
    }
    
    func initializeBalanceIfNeeded() {
        backgroundContext.perform { [weak self] in
            let request: NSFetchRequest<Balance> = Balance.fetchRequest()
            if let existingBalance = (try? self?.backgroundContext.fetch(request))?.first {
                print("Balance already exists: \(existingBalance.amount)")
                return
            }
            
            let balance = Balance(context: self!.backgroundContext)
            balance.amount = 1.0
            self?.saveContext()
            print("Initialized balance with 1 BTC")
        }
    }

}
