//
//  Credentials.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import Foundation

/// A struct to hold the data in the Sign in text fields
struct Credentials: Codable {
    
    /// User's email
    var email: String = ""
    
    /// User's Password
    var password: String = ""
    
    /**
     Initialises the data in the text fields in the Sign in field
     
     - Parameters:
        - rememberPassword: A flag to determine if the user has checked the remember password checkbox.
     */

    /**
     Initialises empty textfields for the sign in fields.
     */
    init() {
        self.email = ""
        self.password = ""
    }
    
    /**
     Initialises the textfields with the email textfield filled.
     
     - Parameters:
        - email: The email that will be displayed in the textfield
    */
    init(email: String) {
        self.email = email
    }
}

/// A struct to hold the data in the Sign Up Page text fields.
struct SignUpCredentials: Codable {
    
    /// The email displayed in the email textfield.
    var email: String = ""
    
    /// The password displayed in the password textfield.
    var password: String = ""
    
    /// The password displayed in the confirm password textfield.
    var confirmPassword: String = ""
}
