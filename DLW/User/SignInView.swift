//
//  SignInView.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import AssetsLibrary
import SwiftUI

/// The different textfields to be focused in the login/signup page.
enum Field: Hashable {
    /// The email textfield
    case usernameField
    
    /// The password textfield
    case passwordField
    
    /// The confirm password textfield
    case confirmPasswordField
    
    /// The name textfield
    case nameField
}

/// This function closes the keyboard in the UI of the app
func closeKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
    )
  }

/// The main login/signup view.
struct SignInView: View {
    
    @EnvironmentObject var authentication: Authentication
    
    /// The singleton instance of the `LoginViewModel`
    @StateObject private var userModel = UserModel.shared
    
    /// An animation namespace for the page.
    @Namespace var name
    
    /**
     Initialises the login/signup page.
     
     The initialiser sets the appearance and colours of the page, including the colour of the text, background and the navigation bar.
     */
    init() {
        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "BackButton")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "BackButton")
        UINavigationBar.appearance().tintColor = .black
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0){
                    // Title
                    VStack(alignment: .leading) {
                        Text("ForU - Rise as one")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(Color("Black1"))
                            .frame(width: UIScreen.main.bounds.width - 50, height: 27, alignment: .leading)
                            .padding(.bottom, 5)
                        Text("Sign in to be healthy together")
                            .font(.system(size: 14))
                            .frame(width: UIScreen.main.bounds.width - 50, height: 16, alignment: .leading)
                            .foregroundColor(Color("Gray1"))
                    }.padding()
                    
                    // Form
                    SignInFormView()
                }.padding(.top, 50)
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .autocapitalization(.none)
            .textFieldStyle(.roundedBorder)
            .disabled(userModel.showProgressView)
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .ignoresSafeArea()
        .statusBar(hidden: false)
        .preferredColorScheme(.light)
    }
}
