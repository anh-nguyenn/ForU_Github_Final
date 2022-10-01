//
//  SignInFormView.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import Foundation
import SwiftUI
import LocalAuthentication

/// Saves the rememberPassword state variable even when app has been closed
struct DefaultKeys {
    static let rememberPasswordKey = "rememberPassword"
}

/// The Sign In Page of the application.
struct SignInFormView : View {
    
    @EnvironmentObject var authentication: Authentication
    
    @StateObject private var userModel = UserModel.shared
    
    @FocusState private var focusedField: Field?
    
    @State var willMoveToNextScreen : Bool = false
    
    @State var rememberPassword: Bool = UserDefaults.standard.bool(forKey: DefaultKeys.rememberPasswordKey)
    
    
    var body: some View {
        VStack {
            // Email input file
            VStack(alignment: .leading) {
                
                if userModel.signupSuccess {
                    Text("You may now log in with your email and password.")
                        .font(.system(size: 13))
                        .foregroundColor(Color("Gray"))
                        .fontWeight(.bold)
                        .padding([.bottom])
                }
                
                ZStack(alignment: .leading){
                    Text("Email")
                        .foregroundColor(userModel.credentials.email == "" ? Color(.placeholderText) : Color("Black1"))
                        .offset(y: userModel.credentials.email == "" ? 0 : -30)
                        .scaleEffect(userModel.credentials.email == "" ? 1 : 0.5, anchor: .leading)
                    
                    TextField("", text: $userModel.credentials.email)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .background(Color.clear)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            focusedField = .passwordField
                    }

                }
                .padding()
                .animation(userModel.credentials.email.count < 2 ? .default : .none)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("Gray2"), lineWidth: 1)
                )
            }
            .padding(.horizontal)

            // Password input field
            VStack (alignment: .leading) {
                ZStack(alignment: .leading){
                    Text("Password")
                        .foregroundColor(userModel.credentials.password == "" ? Color(.placeholderText) : Color("Black1"))
                        .offset(y: userModel.credentials.password == "" ? 0 : -30)
                        .scaleEffect(userModel.credentials.password == "" ? 1 : 0.5, anchor: .leading)
                    
                    SecureTextField(text: $userModel.credentials.password)
                        .focused($focusedField, equals: .passwordField)
                        .submitLabel(.go)
                        .onSubmit {
                            closeKeyboard()
                            Task {
                                await userModel.login {
                                    success in
                                    authentication.updateValidation(success: success)
                                }
                            }
                        }
                        .background(Color.clear)
                        .textFieldStyle(.plain)

                }
                .padding()
                .animation(userModel.credentials.password.count < 2 ? .default : .none)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("Gray2"), lineWidth: 1)
                )
                
            }
            .padding()

            
            if userModel.showProgressView {
                ProgressView()
            }
            if userModel.loginFailed {
                Text("Incorrect username or password!")
                    .foregroundColor(.red)
            }
           
    
            // Sign in button
            Button(action: {
                closeKeyboard()
                userModel.loginFailed = false
                userModel.showProgressView = true
                Task{
                    await userModel.login {
                        success in
                        if success {
                            willMoveToNextScreen = true
                            userModel.signupSuccess = false
                            authentication.updateValidation(success: success)
                        }
                    }
                }
            }) {
                Text("Sign in")
                    .frame(width: UIScreen.main.bounds.width - 50, height: 19, alignment: .center)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.vertical)
                    .foregroundColor(.black)
                    .background(Color("Blue1"))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
            }
            .disabled(userModel.loginDisabled)
            .padding()

            
            // Navigate to SignUpView
            VStack (alignment: .leading) {
                HStack{
                    Text("Do not have an account?")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color("Black1"))
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color("Gray"))
                    }
                    .isDetailLink(false)
                }
            }
        }
        .padding()
        .onAppear(perform: authenticateByFaceID)
        
    }
    
    func authenticateByFaceID()  {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "We need to access your face"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            {success, authenticationError in DispatchQueue.main.async {
                if success {
                    let defaults = UserDefaults.standard
                    if defaults.string(forKey: DefaultsKeys.isSignedIn) == "true"{
                        print("Hello")
                        willMoveToNextScreen = true
                        userModel.signupSuccess = false
                        authentication.updateValidation(success: true)
                    }
                    
                } else {
                    //
                }
            }
            }
        }
    }
}

