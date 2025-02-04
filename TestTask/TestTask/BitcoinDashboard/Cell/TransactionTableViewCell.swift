//
//  TransactionTableViewCell.swift
//  TestTask
//
//  Created by Максим Педько on 04.02.2025.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let leftStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillProportionally
        return stack
    }()
    
    private let rightStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillProportionally
        stack.alignment = .trailing
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        leftStackView.addArrangedSubview(categoryLabel)
        leftStackView.addArrangedSubview(dateLabel)
        
        rightStackView.addArrangedSubview(amountLabel)
        
        contentView.addSubview(leftStackView)
        contentView.addSubview(rightStackView)
        
        leftStackView.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            leftStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leftStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            leftStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            rightStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rightStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            rightStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            leftStackView.trailingAnchor.constraint(lessThanOrEqualTo: rightStackView.leadingAnchor, constant: -16)
        ])
    }
    
    func configure(with transaction: Transaction, bitcoinRate: Double) {
        categoryLabel.text = transaction.category?.capitalized
        amountLabel.text = String(format: "%.8f BTC", transaction.amount)
        dateLabel.text = transaction.date?.formatted(date: .abbreviated, time: .shortened)
    }
    
}
