//
//  ProgramCategoryView.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import SwiftUI

struct ProgramCategoryView: View {
    var body: some View {
        VStack {
            // Knee
            KneeCategoryView()
                .padding(.bottom)

            // Shoulder
            ShoulderCategoryView()
                .padding(.bottom)

            // Back
            BackCategoryView()
                .padding(.bottom)
        }
        .padding(.vertical)
        .padding(.horizontal, 20)
    }
}

struct KneeCategoryView: View {
    var body: some View {
        VStack (alignment: .leading) {
            NavigationLink(destination: KneeProgramView()) {
                HStack{
                    VStack (alignment: .leading) {
                        Text("KNEE")
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(height: 29, alignment: .leading)
                        Text("Choose if you")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Text("have knee pain.")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Text("Click! Click!")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Image("BlackStartButton")
                            .padding(.top, 30)
                    }.padding()
                    
                    Spacer()
                    
                    VStack {
                        Image("KneeProgram")
                
                    }
                }
            }
            .isDetailLink(false)
        }
        .background(Color("Pink1"))
        .cornerRadius(10)
    }
}

struct ShoulderCategoryView: View {
    var body: some View {
        VStack (alignment: .leading) {
            NavigationLink(destination: ShoulderProgramView()) {
                HStack{
                    VStack {
                        Image("ShoulderProgram")
                
                    }
                    
                    Spacer()

                    
                    VStack (alignment: .leading) {
                        Text("SHOULDER")
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(height: 29, alignment: .leading)
                        Text("Choose if having")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Text("shoulder pain.")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Text("Click! Click!")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Image("BlackStartButton")
                            .padding(.top, 30)
                    }.padding()
                }
            }
            .isDetailLink(false)
        }
        .background(Color("Blue1"))
        .cornerRadius(10)
    }
}

struct BackCategoryView: View {
    var body: some View {
        VStack (alignment: .leading) {
//            NavigationLink(destination: BackProgramView()) { change
                HStack{
                    VStack (alignment: .leading) {
                        Text("BACK")
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(height: 29, alignment: .leading)
                        Text("Choose if you")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Text("have back pain.")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Text("Click! Click!")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        Image("BlackStartButton")
                            .padding(.top, 30)
                    }.padding()
                    
                    Spacer()
                    
                    VStack {
                        Image("BackProgram")
                
                    }
                }
//            }
//            .isDetailLink(false) change
        }
        .background(Color("Gray"))
        .cornerRadius(10)
    }
}
