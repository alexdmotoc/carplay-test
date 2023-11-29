//
//  ViewController.swift
//  test-carplay
//
//  Created by Alex Motoc on 26.11.2023.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet private weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateButtonTitle()
    }
    
    @IBAction private func didTapLogin() {
        User.shared.isLoggedIn.toggle()
        updateButtonTitle()
    }
    
    @IBAction private func didTapEnableLocation() {
        CLLocationManager().requestWhenInUseAuthorization()
    }
    
    private func updateButtonTitle() {
        let buttonTitle = User.shared.isLoggedIn ? "Log out" : "Log in"
        loginButton.setTitle(buttonTitle, for: .normal)
    }
}

