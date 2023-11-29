//
//  User.swift
//  test-carplay
//
//  Created by Alex Motoc on 29.11.2023.
//

import Foundation

final class User {
    static let shared = User()
    
    var didChangeLoginStatus: ((Bool) -> Void)?
    
    var isLoggedIn: Bool {
        get { UserDefaults.standard.bool(forKey: "isLoggedIn") }
        set {
            UserDefaults.standard.set(newValue, forKey: "isLoggedIn")
            didChangeLoginStatus?(newValue)
        }
    }
    
    private init() {}
}
