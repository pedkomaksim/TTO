//
//  AddTransactionViewController.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import UIKit
import Combine
import Foundation

class AddTransactionViewController: NiblessViewController {
    
    private var selectedCategory: TransactionCategory = .groceries
    private var cancellables = Set<AnyCancellable>()
    
    private let amountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter amount"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        return textField
    }()
    
    private let categoryPicker: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.addTarget(self, action: #selector(addTransaction), for: .touchUpInside)
        return button
    }()
    
    private let model: AddTransactionModel
    
    init(model: AddTransactionModel) {
        self.model = model
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        
        setupUI()
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [amountTextField, categoryPicker, addButton])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func addTransaction() {
        guard let amountText = amountTextField.text, let amount = Double(amountText) else { return }
        model.addTransaction(amount: amount, category: selectedCategory.rawValue, date: Date())
        navigationController?.popViewController(animated: true)
    }
}

extension AddTransactionViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TransactionCategory.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return TransactionCategory.allCases[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCategory = TransactionCategory.allCases[row]
    }
    
}
