//
//  ShoulderListView.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import SwiftUI
import UIKit

struct ShoulderListView: View {
    
    @Binding var movesChosen: [DraggableMove]
    @Binding var searchString: String
    
    var body: some View {
        ScrollView {
            Spacer(minLength: 15)
            Text("Exercises")
                .font(.system(size: 22))
                .fontWeight(.semibold)
                .foregroundColor(Color("Black2"))
                .frame(width: UIScreen.main.bounds.width - 50, height: 27, alignment: .leading)
                .padding()
                
            ForEach(shoulderList, id: \.self) { move in
                if searchString == "" {
                    MoveAddRow(move: move, moves: $movesChosen)
                } else {
                    if move.name.lowercased().contains(searchString.lowercased()) {
                        MoveAddRow(move: move, moves: $movesChosen)
                    }
                }
            }
            
        }
        .listRowSeparator(.visible)
    }
    
    let shoulderList: [Move]  = [
        BandedRotationModel(),
        PosteriorCapsuleStretchModel(),
        StandingKneeBendModel()
    ]
    
    
    struct MoveAddRow: View {

        @State var selection: Int? = nil
        @State var side: Move.Side? = nil
        @State var sideText: String = ""
        var placeholder: String = "Select Side"
        var move: Move
        var dropdownListTypeOne: [String] = ["Left", "Right", "Both"]
        var dropdownListTypeTwo: [String] = ["Left", "Right"]
        @Binding var moves: [DraggableMove]
        
        var disableButton: Bool {
            (moves.count > 0 && moves[moves.count - 1].move.id == move.id) || (side == nil && (move.type == 1 || move.type == 2))
        }
        
        var body: some View {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        temp(image: move.smallImage)
                            .frame(minWidth: 0, maxWidth: 50, minHeight: 0, maxHeight: 50)
                            .cornerRadius(5)
                        Spacer()
                            .frame(width: 20, height: 50)
                        VStack {
                            Text(move.name)
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color("Black1"))
                                .frame(minWidth: 0, maxWidth: 180, alignment: .leading)
                        }
                        .frame(width: 200, height: 50, alignment: .leading)

                        Spacer()
                        Button {
                            moves.append(DraggableMove(id: DraggableMove.getNewId(), move: move.getShared()))
                            move.getShared().side = self.side
                        } label: {
                            Image("AddButton")
                        }
                        .disabled(disableButton)
                    }
                    .onTapGesture {
                        if !disableButton {
                            moves.append(DraggableMove(id: DraggableMove.getNewId(), move: move.getShared()))
                        }
                    }
                    if move.type == 1 {
                        Spacer()
                        Menu {
                            ForEach(dropdownListTypeOne, id: \.self) { side in
                                Button(side) {
                                    switch(side){
                                    case "Left":
                                        self.sideText = side
                                        self.side = .left
                                        break
                                    case "Right":
                                        self.sideText = side
                                        self.side = .right
                                        break
                                    case "Both":
                                        self.sideText = side
                                        self.side = .both
                                        break
                                    default:
                                        self.sideText = "Right"
                                        self.side = .right
                                        break
                                    }
                                }
                            }
                        } label: {
//                            VStack(spacing: 5) {
//                                HStack {
//                                    Text(side == nil ? placeholder : self.sideText)
//                                        .foregroundColor(side == nil ? .gray : .black)
//                                    Spacer()
//                                    Image(systemName: "chevron.down")
//                                                           .foregroundColor(Color("Blue1"))
//                                                           .font(Font.system(size: 16, weight: .bold))
//                                }
//                                Rectangle()
//                                    .fill(Color("Blue1"))
//                                    .frame(height: 2)
//                            }.padding(.top)
                        }
                    }
                    if move.type == 2 {
                        Spacer()
                        Menu {
                            ForEach(dropdownListTypeTwo, id: \.self) { side in
                                Button(side) {
                                    switch(side){
                                    case "Left":
                                        self.sideText = side
                                        self.side = .left
                                        break
                                    case "Right":
                                        self.sideText = side
                                        self.side = .right
                                        break
                                    default:
                                        self.sideText = side
                                        self.side = nil
                                        break
                                    }
                                }
                            }
                        } label: {
                            VStack(spacing: 5) {
                                HStack {
                                    Text(side == nil ? placeholder : self.sideText)
                                        .foregroundColor(side == nil ? .gray : .black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Color("Blue1"))
                                        .font(Font.system(size: 16, weight: .bold))
                                }
                                Rectangle()
                                    .fill(Color("Blue1"))
                                    .frame(height: 2)
                            }.padding(.top)
                        }
                    }
                        
                }.padding()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                .stroke(Color("Gray2"), lineWidth: 1)
            )
            .padding(.bottom)
            .padding(.horizontal, 26)
        }
    }
    
    /// Wraps UIView in a View for Gif.
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

