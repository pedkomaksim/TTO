//
//  BitcoinDashboardViewController.swift
//  TestTask
//
//  Created by Максим Педько on 04.02.2025.
//

import UIKit
import Combine

class BitcoinDashboardViewController: NiblessViewController {
    
    let model: BitcoinDashboardModel
    
    private let tableView = UITableView()
    private let bitcoinRateLabel = UILabel()
    private let balanceLabel = UILabel()
    private var bitcoinRate: Double = 0.0
    
    private var groupedTransactions: [Date: [Transaction]] = [:]
    private var sortedDates: [Date] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var indexx = 0
    
    init(model: BitcoinDashboardModel) {
        self.model = model
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupBindings() {
        model.bitcoinRateService.bitcoinRatePublisher
            .sink { [weak self] rate in
                self?.bitcoinRateLabel.text = "Bitcoin rate: \(rate ?? 0) $"
                print("Updated Bitcoin rate: \(rate ?? 0)")
            }
            .store(in: &cancellables)
        
        model.$balance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balance in
                self?.balanceLabel.text = "Balance: \(balance) BTC"
            }
            .store(in: &cancellables)
        
        model.$groupedTransactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groupedTransactions in
                self?.groupedTransactions = groupedTransactions
                self?.sortedDates = groupedTransactions.keys.sorted(by: >)
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "Bitcoin Dashboard"
        
        bitcoinRateLabel.font = .systemFont(ofSize: 14)
        bitcoinRateLabel.textAlignment = .right
        view.addSubview(bitcoinRateLabel)
        bitcoinRateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bitcoinRateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12.0),
            bitcoinRateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12.0)
        ])
        
        balanceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        balanceLabel.textAlignment = .center
        view.addSubview(balanceLabel)
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            balanceLabel.topAnchor.constraint(equalTo: bitcoinRateLabel.bottomAnchor, constant: 5.0),
            balanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0),
            balanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0)
        ])
        
        let addTransactionButton = UIButton(type: .system)
        addTransactionButton.setTitle("Add Transaction", for: .normal)
        addTransactionButton.addTarget(self, action: #selector(openAddTransaction), for: .touchUpInside)
        
        let toUpBalanceButton = UIButton(type: .system)
        toUpBalanceButton.setTitle("Top up balance", for: .normal)
        toUpBalanceButton.addTarget(self, action: #selector(toUpBalanceAction), for: .touchUpInside)
        
        let buttonStackView = UIStackView(arrangedSubviews: [addTransactionButton, toUpBalanceButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        
        view.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 20),
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: "TransactionTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func openAddTransaction() {
        model.showAddTransaction()
    }
    
    @objc private func toUpBalanceAction() {
        
        let alertController = UIAlertController(title: "Top Up Balance", message: "Enter amount in BTC", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            if let amountText = alertController.textFields?.first?.text, let amount = Double(amountText) {
                self?.model.updateBalance(by: amount)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
}

extension BitcoinDashboardViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedDates.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = sortedDates[section]
        return groupedTransactions[date]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell", for: indexPath) as! TransactionTableViewCell
        let date = sortedDates[indexPath.section]
        if let transaction = groupedTransactions[date]?[indexPath.row] {
            cell.configure(with: transaction, bitcoinRate: bitcoinRate)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = sortedDates[section]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    
}

extension BitcoinDashboardViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSection = sortedDates.count - 1
        guard lastSection >= 0, !model.isFetchingTransactions else { return }

        let lastRow = (groupedTransactions[sortedDates[lastSection]]?.count ?? 1) - 1
        if indexPath.section == lastSection && indexPath.row == lastRow {
            print("pagination \(indexx)")
            indexx += 1
            model.fetchTransactions()
        }
    }
    
}
