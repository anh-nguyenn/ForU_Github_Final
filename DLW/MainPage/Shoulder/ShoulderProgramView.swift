//
//  ShoulderProgramView.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import AVFoundation

struct ShoulderProgramView: View {
    
    @EnvironmentObject var authentication: Authentication
    @StateObject private var model = HomepageModel()

    @State private var searchString = ""
    @State private var movesChosen: [DraggableMove] = []
    @State private var confidence = GlobalSettings.getDefaultConfidence()
        
    
    @State var index = 0
    @Namespace var name
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    VStack {
                        Divider()
                            .font(.system(size: 3))
                            .frame(width: UIScreen.main.bounds.width)
                            .foregroundColor(Color("Blue1"))
                    }
                    .padding(.bottom, 30)
                                    
                    
                    ShoulderListView(movesChosen: $model.data, searchString: $searchString)
                    
                    

                    if model.data.count > 0 {
                        VStack{
                            Divider()
                                .font(.system(size: 3))
                                .frame(width: UIScreen.main.bounds.width)
                                .foregroundColor(Color("Blue1"))

                            HStack {
                                Text("My Routine")
                                    .font(.system(size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("Black2"))
                                Spacer()
                                Button {
                                    model.data = []

                                } label: {
                                    Text("Clear")
                                        .foregroundColor(Color("Blue1"))
                                }
                                .opacity(model.data.count <= 0 ? 0 : 1)
                                .disabled(model.data.count <= 0)
                            }
                            .padding([.horizontal, .top])
                            DragRelocateView(model: model)
                        }
                    }
                        
                }.padding(.top, 110)
                
            }
        }
        .preferredColorScheme(.light)
        .statusBar(hidden: false)
        .onAppear {
            model.data = []
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
                if response {
                    print("Access Granted")
                } else {
                    print("Access Denied")
                }
            }
            index = 0
        }
        .navigationTitle("SHOULDER PROGRAMS")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .ignoresSafeArea()
        .statusBar(hidden: false)
    }
    
    
    
    /// View of the entire currently selected Draggable Moves.
    ///
    /// Scrollable Horiziontal List representation allowing users to reorder the Moves as required.
    /// Missing features:
    /// * Delete Move after Selection (without the `Clear`Button)
    /// * Gif/Image Representation of the Moves
    struct DragRelocateView: View {
        
        @StateObject var model: HomepageModel
        @State private var dragging: DraggableMove?
        @State private var changedView: Bool = false
        

        var body: some View {
            VStack {
                ScrollView(.horizontal) {
                   LazyHGrid(rows: model.rows, spacing: 5) {
                        ForEach(model.data) { d in
                            DraggableMoveView(data: d, draggableMoves: $model.data)
                                .opacity(dragging?.id == d.id && changedView ? 0 : 1)
                                .onDrag {
                                    self.dragging = d
                                    changedView = false
                                    return NSItemProvider(object: String(d.id) as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: d, listData: $model.data, current: $dragging, changedView: $changedView))
                        }
                    }
                   .animation(.default, value: model.data)
                   .padding()
                }
                
                
                NavigationLink(destination: ShoulderConfirmView(movesChosen: $model.data)) {
                    HStack (alignment: .center) {
                        Text("Start ")
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color.white)
                        Image("StartButton")
                    }
                    .frame(width: UIScreen.main.bounds.width - 50, height: 19, alignment: .center)
                    .padding(.vertical, 8)
                }
                .isDetailLink(false)
                .background(Color("Blue1"))
                .disabled(model.data.count <= 0)
                .opacity(model.data.count <= 0 ? 0 : 1)
                .buttonStyle(.bordered)
                .cornerRadius(10)
                .padding(.bottom, 25)
                
            }
            .onDrop(of: [UTType.text], delegate: DropOutsideDelegate(current: $dragging, changedView: $changedView))
        }
    }

}
