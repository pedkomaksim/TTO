//
//  NiblessViewController.swift
//  TestTask
//
//  Created by Максим Педько on 04.02.2025.
//

import Foundation
import UIKit

open class NiblessViewController: UIViewController {
 
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Init is not implemented")
    }
    
 
}
