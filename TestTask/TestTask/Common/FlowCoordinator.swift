//
//  FlowCoordinator.swift
//  TestTask
//
//  Created by Максим Педько on 04.02.2025.
//

import UIKit

protocol FlowCoordinator {
    
    var containerViewController: UIViewController? { get set }
    
    @discardableResult
    func createFlow() -> UIViewController
    
}
