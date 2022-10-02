//
//  MoveView.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import SVGKit
import SwiftUI
import ConfettiSwiftUI

struct MoveView: View {

    @State private var counter: Int = 0
    
    @State private var moveData: [[String : Int]] = []
    
    @State private var exitFromMoveView: Bool = false
    
    private var moves: [DraggableMove] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var currentMoveIndex: Int = 0
    
    @State var showNotificationMessage: Bool = true

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(moves: [DraggableMove]) {
        self.moves = moves
    }
    
    var body: some View {
        
        ZStack {
            if !finished() {
                getMove(id: moves[currentMoveIndex].move.id)
                    .onAppear {
                        moves[currentMoveIndex].move.getShared().transitionTimerIsActive = true
                    }
            }
            VStack {
                HStack {
                    Button {
                        completeAllExercises(moves: moves)
                        resetAll(moves: moves)
                        didDismiss()
                        exitFromMoveView = true
                    } label: {
                        Image("BackButton")
                            .padding(.leading, finished() ? 20 : 0)
                    }
                    
                    
                    Spacer()
                    if finished() {
                        Text("SUMMARY")
                            .foregroundColor(Color("Black1"))
                            .font(.system(size: 18))
                            .fontWeight(.medium)
                            .padding(.leading, -20)
                        Spacer()
                        Text("")
                    }
                    Group {
                        if !finished() {
                            Button {
                                let currentMove =  moves[currentMoveIndex].move
                                let sharedMove = currentMove.getShared()
                                showNotificationMessage = false
                                if sharedMove.instructed {
                                    
                                    let data = generateMoveData(move: sharedMove)
                                    moveData.append(data)
                                    
                                    Move.finishedReps += data["completedReps"]!
                                    Move.totalReps += data["totalReps"]!
                                    sharedMove.exerciseCompleted = true
                                    currentMoveIndex += 1
                                    sharedMove.setNotInstructed(firstExercise: currentMoveIndex == 0)
                                    sharedMove.resetStateMachine()
                                    if !finished() {
                                        moves[currentMoveIndex].move.getShared().transitionTimerIsActive = true
                                    }
                                } else {
                                    sharedMove.setInstructed(firstExercise: currentMoveIndex == 0)
                                }
                            } label: {
                                Text("Skip")
                                    .foregroundColor(Color("Black1"))
                                    .font(.system(size: 18))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                if currentMoveIndex == 0 && showNotificationMessage {
                    VStack {
                        VStack (alignment: .leading) {
                            Image("Alarm")
                                .minimumScaleFactor(1.3)
                            Text("Disable silent mode")
                                .foregroundColor(.black)
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                            Text("Please ensure that your phone is not in silent mode to hear the audio cues!")
                                .foregroundColor(Color("Gray1"))
                                .font(.system(size: 16))
                        }.padding()
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("Gray2"), lineWidth: 1)
                    )
                    .padding(.bottom, 5)
                }
                
                if finished() && !exitFromMoveView {
                    
                    VStack(alignment: .leading) {
                        ScrollView {
                            SummaryView(moves: moves, moveData: moveData)
                                .padding()
                        }
                        vasScaleImage()
                    }
                }
            }
            .onAppear {
                exitFromMoveView = false
                Move.finishedReps = 0
                Move.totalReps = 0
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        .navigationBarHidden(true)
        }
        .onReceive(timer) { time in
            if currentMoveIndex < moves.count && moves[currentMoveIndex].move.getShared().transitionTimerIsActive {
                let currentMove =  moves[currentMoveIndex].move
                let sharedMove = currentMove.getShared()
                if sharedMove.exerciseCompleted || !sharedMove.instructed {
                    if sharedMove.transitionTimer <= 0 {
                        sharedMove.transitionTimer = Move.transitionTime + 1 // +1 as the timer will -1 at the end
                        showNotificationMessage = false
                        if sharedMove.instructed {
                            
                            let data = generateMoveData(move: sharedMove)
                            moveData.append(data)
                            
                            Move.finishedReps += data["completedReps"]!
                            Move.totalReps += data["totalReps"]!
                            
                            currentMoveIndex += 1
                            sharedMove.setNotInstructed(firstExercise: currentMoveIndex == 0)
                            sharedMove.resetStateMachine()
                            if !finished() {
                                moves[currentMoveIndex].move.getShared().transitionTimerIsActive = true
                            }
                        } else {
                            sharedMove.setInstructed(firstExercise: currentMoveIndex == 0)
                        }
                    }
                    sharedMove.transitionTimer -= 1
                } else {
                    sharedMove.transitionTimer = Move.transitionTime + 1
                }
            }
        }
    }
    
    
    struct SummaryView: View {
        @State var moveIndex: Int = 0
        
        private var completedMoves: [DraggableMove] = []
        
        private var moveData: [[String: Int]] = []
        
        init(moves: [DraggableMove], moveData: [[String : Int]]) {
            self.completedMoves = moves
            self.moveData = moveData
        }
        
        var body: some View {
            VStack{
                ForEach(0..<completedMoves.count, id: \.self) { index in
                    let currentMove = completedMoves[index]
                    Divider()
                        .frame(width: UIScreen.main.bounds.width)
                        .foregroundColor(Color("Gray4"))
                        .padding(.bottom, 5)
                    VStack {
                        Text("\(currentMove.move.name)")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                            .frame(width: UIScreen.main.bounds.width - 50, alignment: .center)

                        let data = moveData[index]
                        self.makeSummaryView(side: data["side"]!, totalReps: data["totalReps"]!, completedReps: data["completedReps"]!, totalSets: data["totalSets"]!, completedSets: data["completedSets"]!)
                        }
                    .padding(.bottom, 10)
                    }
            }
            .onAppear{
                AudioManager.speakText(text: TextToSpeech.goodJob)
            }
        }
        
        func makeSummaryView(side: Int, totalReps: Int, completedReps: Int, totalSets: Int, completedSets: Int) -> some View {
            let sideText: String
            switch(side) {
            case 0:
                sideText = "Left"
                break
            case 1:
                sideText = "Right"
                break
            case 2:
                sideText = "Both"
                break
            default:
                sideText = "Both"
            }
            var body: some View {
                VStack {
                    HStack(alignment: .center) {
                        Text("Side Selected: ")
                            .font(.system(size: 16))
                        Text(sideText)
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                    }.padding(.bottom)
                    
                    HStack(alignment: .center) {
                        Text("Sets Completed: ")
                            .font(.system(size: 16))
                        Text("\(completedSets)/\(totalSets)")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                    }.padding(.bottom)

                    HStack(alignment: .center) {
                        Text("Reps Completed: ")
                            .font(.system(size: 16))
                        Text("\(completedReps)/\(totalReps)")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                    }.padding(.bottom)
                }
                .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                .padding(.vertical, 10)

            }
            return body
            }
        }
        
    func resetAll(moves: [DraggableMove]) {
        for move in moves {
            move.move.resetStateMachine()
        }
    }
    func getTitleText() -> String {
        if currentMoveIndex + 1 > moves.count {
            return "Move Completed!"
        } else {
            return moves[currentMoveIndex].move.name
        }
    }
        
    func didDismiss() {
        presentationMode.wrappedValue.dismiss()
        CameraService.terminate()
        AudioManager.stopAll()
        UINavigationBar.appearance().backgroundColor = .white
    }
    
    func completeAllExercises(moves: [DraggableMove]) {
        for move in moves {
            move.move.getShared().exerciseCompleted = true
        }
    }
    
    func finished() -> Bool {
        return currentMoveIndex + 1 > moves.count
    }
    
    @ViewBuilder
    func getMove(id: Int) -> some View {
        switch(id) {
        case BandedRotationModel().id:
            BandedRotationView()
        case PosteriorCapsuleStretchModel().id:
            PosteriorCapsuleStretchView()
        case StandingKneeBendModel().id:
            StandingKneeBendView()
        default:
            PosteriorCapsuleStretchView()
        }
    }
}
