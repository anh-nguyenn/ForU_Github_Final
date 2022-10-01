//
//  SignUpView.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import Foundation
import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    /// Singleton instance of the `LoginViewModel`
    @StateObject private var userModel = UserModel.shared
    
    /// Property wrapper that helps focus on the text fields in the sign up page.
    @FocusState private var focusedField: Field?
    
    var body: some View {
        
        ScrollView {
            ZStack(alignment: .top) {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    // Title
                    VStack(alignment: .leading) {
                        Text("Sign up to ForU")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(Color("Black1"))
                            .frame(width: UIScreen.main.bounds.width - 50, height: 27, alignment: .leading)
                            .padding(.bottom, 5)
                        Text("Sign up to be healthy together")
                            .font(.system(size: 14))
                            .frame(width: UIScreen.main.bounds.width - 50, height: 16, alignment: .leading)
                            .foregroundColor(Color("Gray1"))
                    }.padding()
                    
                    //Form
                    VStack {
                        VStack(alignment: .leading) {
                            ZStack(alignment: .leading){
                                Text("Email")
                                    .foregroundColor(userModel.signupCredentials.email == "" ? Color(.placeholderText) : Color("Black1"))
                                    .offset(y: userModel.signupCredentials.email == "" ? 0 : -30)
                                    .scaleEffect(userModel.signupCredentials.email == "" ? 1 : 0.5, anchor: .leading)
                                
                                TextField("", text: $userModel.signupCredentials.email)
                                    .disableAutocorrection(true)
                                    .keyboardType(.emailAddress)
                                    .background(Color.clear)
                                    .focused($focusedField, equals: .usernameField)
                                    .textFieldStyle(.plain)
                                    .onSubmit {
                                        focusedField = .nameField
                                }

                            }
                            .padding()
                            .animation(userModel.signupCredentials.email.count < 2 ? .default : .none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("Gray2"), lineWidth: 1)
                            )
                        }.padding()
                        
                                 
                        
                        
                        VStack (alignment: .leading) {
                            ZStack(alignment: .leading){
                                Text("Password")
                                    .foregroundColor(userModel.signupCredentials.password == "" ? Color(.placeholderText) : Color("Black1"))
                                    .offset(y: userModel.signupCredentials.password == "" ? 0 : -30)
                                    .scaleEffect(userModel.signupCredentials.password == "" ? 1 : 0.5, anchor: .leading)
                                
                                SecureTextField(text: $userModel.signupCredentials.password)
                                    .disableAutocorrection(true)
                                    .focused($focusedField, equals: .passwordField)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        focusedField = .confirmPasswordField
                                    }
                                    .background(Color.clear)
                                    .textFieldStyle(.plain)

                            }
                            .padding()
                            .animation(userModel.signupCredentials.password.count < 2 ? .default : .none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("Gray2"), lineWidth: 1)
                            )
                        }.padding([.horizontal, .bottom])
                    
                        VStack (alignment: .leading) {
                            ZStack(alignment: .leading){
                                Text("Confirm Password")
                                    .foregroundColor(userModel.signupCredentials.confirmPassword == "" ? Color(.placeholderText) : Color("Black1"))
                                    .offset(y: userModel.signupCredentials.confirmPassword == "" ? 0 : -30)
                                    .scaleEffect(userModel.signupCredentials.confirmPassword == "" ? 1 : 0.5, anchor: .leading)
                                
                                SecureTextField(text: $userModel.signupCredentials.confirmPassword)
                                    .disableAutocorrection(true)
                                    .focused($focusedField, equals: .confirmPasswordField)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        closeKeyboard()
                                        Task {
                                            if userModel.signupCredentials.confirmPassword == userModel.signupCredentials.password {
                                                await userModel.signup {
                                                    success in
                                    
                                                }
                                            }
                                        }
                                    }
                                    .background(Color.clear)
                                    .textFieldStyle(.plain)

                            }
                            .padding()
                            .animation(userModel.signupCredentials.confirmPassword.count < 2 ? .default : .none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("Gray2"), lineWidth: 1)
                            )
                        }.padding([.horizontal, .bottom])
                        
                        Group {
                            if userModel.showProgressView {
                                ProgressView()
                            }
                            if !userModel.signupSuccess && userModel.showSignUpError {
                                Text(userModel.errorMessage)
                                    .foregroundColor(.red)
                            }
                            if userModel.passwordDifferent {
                                Text("Passwords must be identical")
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: {
                                closeKeyboard()
                                Task {
                                    if userModel.signupCredentials.confirmPassword == userModel.signupCredentials.password {
                                        await userModel.signup {
                                            success in
                                            if success {
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    }
                                }
                            }) {
                                Text("Sign up")
                                    .frame(width: UIScreen.main.bounds.width - 50, height: 19, alignment: .center)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.vertical)
                                    .foregroundColor(.black)
                                    .background(Color("Blue1"))
                                    .cornerRadius(8)
                                    .contentShape(Rectangle())
                            }
                            .disabled(userModel.signupDisabled || userModel.showProgressView)
                            
        
                        }.padding([.horizontal, .bottom])
                        
                        
                        VStack (alignment: .leading) {
                            HStack{
                                Text("Already have an account?")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(Color("Black1"))

                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Sign in")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color("Gray"))
                                }
                            }
                        }.padding([.horizontal, .bottom])
                    }.padding(.horizontal, 10)
                }.padding(.top, 95)
            }
            .navigationTitle("")
        }
        .ignoresSafeArea()
    }
}
