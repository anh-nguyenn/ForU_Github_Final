//
//  KneeConfirmView.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import SwiftUI

struct KneeConfirmView: View {
    /// List of all Moves to be executed sorted by execution order
    @Binding var movesChosen: [DraggableMove]
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            ZStack (alignment: .top){
                Color.white.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    VStack (alignment: .leading) {
                        VStack {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image("BackButton")
                            }
                            .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                            
                            Text("Knee")
                                .font(.system(size: 36))
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                                .padding(.bottom)

                            HStack {
                                Text("Each program targets specific muscle areas")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black)
                                    .frame(width: UIScreen.main.bounds.width / 2 , alignment: .leading)
                                    .padding(.horizontal)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom)
                            
                            VStack {
                                NavigationLink(destination: MoveView(moves: movesChosen)) {
                                    HStack (alignment: .center) {
                                        Text("Start ")
                                            .font(.system(size: 18))
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.black)
                                        Image("BlackStartButton")
                                    }
                                    .padding(.vertical)
                                    .padding(.horizontal, 30)
                                }
                                .background(.white)
                                .cornerRadius(10)
                                .simultaneousGesture(TapGesture().onEnded {
                                })
                            }
                            .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image("KneeProgram")
                            .minimumScaleFactor(1.3)
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .background(Color("Blue1"))
                    
                    ScrollView {
                        
                        VStack {
                            Text("Exercises")
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(Color("Black1"))
                                .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                        }.padding()
                    
                        ForEach(movesChosen) { move in
                                KneeRow(data: move)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: false)
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

struct KneeRow: View {
    
    var data: DraggableMove

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    temp(image: data.move.smallImage)
                        .frame(minWidth: 0, maxWidth: 50, minHeight: 0, maxHeight: 50)
                        .cornerRadius(5)
                    Spacer()
                        .frame(width: 5, height: 50)
                    VStack {
                        Text(data.move.name)
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color("Black1"))
                            .frame(minWidth: 0, maxWidth: 180, alignment: .leading)
                    }
                    .frame(width: 200, height: 50, alignment: .leading)

                    Spacer()
                    
                    Text("1:30")
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                }
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
            .stroke(Color("Gray2"), lineWidth: 1)
        )
        .padding(.bottom)
        .padding(.horizontal, 26)
    }
    
    struct temp : UIViewRepresentable {
        var image: UIImage
        init(image: UIImage) {
            self.image = image
        }
        
        func makeUIView(context: Context) -> some UIView {
            UIImageView(image: self.image)
        }
        
        func updateUIView(_ uiView: UIViewType, context: Context) { }
    }
}

