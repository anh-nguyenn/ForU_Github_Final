//
//  Authentication.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import SwiftUI

class Authentication: ObservableObject {
    @Published var isValidated: Bool = false
    
    func updateValidation(success: Bool) {
        DispatchQueue.main.async {
            withAnimation {
                self.isValidated = success
            }
        }
    }
}
