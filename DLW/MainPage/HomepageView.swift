//
//  HomepageView.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import Foundation
import SwiftUI

struct HomepageView: View {
    
    @EnvironmentObject var authentication: Authentication
    
    
    @State var index = 1
    
    @Namespace var name
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack {
                    VStack(spacing: 0) {
                        if index == 0 {
                            HStack {
                                Text("EXPLORE")
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("Black1"))
//                                    .frame(width: UIScreen.main.bounds.width - 50, height: 19, alignment: .center)
                                    .padding()
                                
                                Spacer()
                                
                                Button("Log Out") {
                                    Task {
                                        let defaults = UserDefaults.standard
                                        defaults.set("false", forKey: DefaultsKeys.isSignedIn)
                                        authentication.updateValidation(success: false)
                                    }
                                }
                                .background(Color.red)
                                .foregroundColor(.white)
                                .buttonStyle(.bordered)
                                .font(.system(size: 16))
                                .cornerRadius(10)
                            }.padding(.horizontal, 10)

                            
                            Divider()
                                .font(.system(size: 3))
                                .frame(width: UIScreen.main.bounds.width)
                                .foregroundColor(Color("Blue1"))
                            
                            ScrollView {
                                ProgramCategoryView()
                            }
                            
                        } else if index == 1 {
                            HStack {
                                Text("PROFILE")
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("Black1"))
                                    .padding()
                                
                                Spacer()
                                
                                Button("Log Out") {
                                    Task {
                                        let defaults = UserDefaults.standard
                                        defaults.set("false", forKey: DefaultsKeys.isSignedIn)
                                        authentication.updateValidation(success: false)
                                    }
                                }
                                .background(Color.red)
                                .foregroundColor(.white)
                                .buttonStyle(.bordered)
                                .font(.system(size: 16))
                                .cornerRadius(10)
                            }.padding(.horizontal, 10)
                            
                            Divider()
                                .font(.system(size: 3))
                                .frame(width: UIScreen.main.bounds.width)
                                .foregroundColor(Color("Blue1"))
                            
                            ScrollView {
                                ProfileView()
                            }
                            
                            
                        }
            
                    }.padding()
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        
                        Button(action: {

                            withAnimation(.spring()) {
                                index = 1
                            }
                            
                        }) {
                            VStack {
                                ZStack{
                                    Rectangle()
                                        .fill(Color.black.opacity(0.04))
                                        .frame(height: 4)
                                    if index == 1 {
                                        Rectangle()
                                            .fill(Color("Blue1"))
                                            .frame(height: 4)
                                            .matchedGeometryEffect(id: "Tab", in: name)
                                    }
                                }.padding(.bottom)
                                
                                index == 1 ? Image("BlueProfile") : Image("BlackProfile")
                            }
                        }
                        
                        Button(action: {
                            
                            withAnimation(.spring()) {
                                index = 0
                            }
                            
                        }) {
                            VStack {
                                ZStack{
                                    Rectangle()
                                        .fill(Color.black.opacity(0.04))
                                        .frame(height: 4)
                                    if index == 0 {
                                        Rectangle()
                                            .fill(Color("Blue1"))
                                            .frame(height: 4)
                                            .matchedGeometryEffect(id: "Tab", in: name)
                                    }
                                }.padding(.bottom)
                                
                                index == 0 ? Image("BlueProgram") : Image("BlackProgram")
                            }
                        }
                        
                    }
                }
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .autocapitalization(.none)
            .textFieldStyle(.roundedBorder)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .ignoresSafeArea()
        .statusBar(hidden: false)
        .preferredColorScheme(.light)
    }
}
