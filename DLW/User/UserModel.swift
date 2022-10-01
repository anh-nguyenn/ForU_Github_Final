//
//  UserModel.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import Foundation

/// The model of the Login View.
class UserModel: ObservableObject {
    /// The singleton instance of `LoginViewModel`
    static var shared: UserModel = UserModel()
    
    /// Sign in credentials.
    @Published var credentials: Credentials = Credentials()
    
    /// A Flag to determine if the login has failed.
    @Published var loginFailed: Bool = false
    
    /// A variable to store the JWT retrieved from cognito after a successful log in.
    @Published var accessToken: String = ""
    
        
    /// Sign Up Credentials.
    @Published var signupCredentials: SignUpCredentials = SignUpCredentials()
    
    /// A flag to determine if the sign up was successful.
    @Published var signupSuccess: Bool = false
    
    /// A flag to determine if the app should show the sign up error message.
    @Published var showSignUpError: Bool = false
    
    
    /// A flag to determine if the app should show the loading animation.
    @Published var showProgressView = false
    
    /// The error message that is presented to the user in the case that any of the sign in/sign up steps were unsuccessful.
    @Published var errorMessage: String = ""
    
    /// A flag to determine if the 'Log In' button should be disabled or not.
    var loginDisabled: Bool {
      credentials.email.isEmpty || credentials.password.isEmpty
    }
    
    /// A flag to determine if the 'Sign Up' button should be disabled or not.
    var signupDisabled: Bool {
        signupCredentials.email.isEmpty || signupCredentials.password.isEmpty || signupCredentials.confirmPassword.isEmpty
    }
    
    /// A flag to determine if the password in the password and confirm password fields in the sign up page are not identical.
    var passwordDifferent: Bool {
        signupCredentials.password != signupCredentials.confirmPassword
    }
    
    
    /// A flag to determine if the email field in the log in page is empty.
    var emailEmpty: Bool {
        credentials.email.isEmpty
    }
    
    /// A decoder of the JSON outputs from the backend server.
    struct Response: Codable {
        let error: Bool
        let success: Bool
        let message: String
    }
    
    /// The function that handles the log in of the user.
    func login(completion: @escaping (Bool) -> Void) async {
        await UserController.shared.login(credentials: credentials) { [unowned self] (result: Result<Bool,UserController.UserControllerError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.showProgressView = false
                    self.loginFailed = false
                    completion(true)
                    UserDefaults.standard.set(self.credentials.email, forKey: "savedEmail")
                case .failure:
                    self.showProgressView = false
                    self.loginFailed = true
                    self.credentials = Credentials()
                    completion(false)
                }
            }
        }
    }
    
    /// The function that handles the sign up of the user.
    func signup(completion: @escaping (Bool) -> Void) async {
        await UserController.shared.signup(signupCredentials: signupCredentials) { [unowned self] (result: Result<Bool,UserController.UserControllerError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.showProgressView = false
                    self.signupSuccess = true
                    self.showSignUpError = false
                    self.signupCredentials = SignUpCredentials()
                    completion(true)
                    UserDefaults.standard.set(self.credentials.email, forKey: "savedEmail")
                case .failure:
                    self.showProgressView = false
                    self.signupSuccess = false
                    self.showSignUpError = true
                    completion(false)
                }
            }
        }
    }

}

