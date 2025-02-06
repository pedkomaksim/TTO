//
//  FlowCoordinator.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import UIKit

protocol FlowCoordinator {
    
    var containerViewController: UIViewController? { get set }
    
    @discardableResult
    func createFlow() -> UIViewController
    
}
