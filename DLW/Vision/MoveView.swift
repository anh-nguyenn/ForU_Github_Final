//
//  MoveView.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import SVGKit
import SwiftUI
import ConfettiSwiftUI

/// A wrapper View for all the Views that are to be displayed in sequence
struct MoveView: View {

    /// A variable that causes the confetti to appear in the summary page when it is incremented.
    @State private var counter: Int = 0
    
    /// An array of dictionaries for the data of each exercises in the exercise queue.
    @State private var moveData: [[String : Int]] = []
    
    /// A flag to determine if the app is exiting from the `MoveView`
    @State private var exitFromMoveView: Bool = false
    
    /// List of all Moves to be executed sorted by execution order
    private var moves: [DraggableMove] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    /// Index of the moves array to determine which exercise to execute.
    @State var currentMoveIndex: Int = 0
    
    /// A flag to determine if the app should show the message to switch off silent mode.
    @State var showNotificationMessage: Bool = true

    // Timer that is used to control the hands off control of the MoveView
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    /// Initialises the MoveView with the array of moves to be completed
    ///
    /// - Parameters
    ///     - moves: The list of Moves to be executed
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
    
    
    /// A view to show the summary of all the exercises completed at the end of the session.
    struct SummaryView: View {
        
        /// Index of the completedMoves array.
        @State var moveIndex: Int = 0
        
        /// An array consisting of the completed moves in the session.
        private var completedMoves: [DraggableMove] = []
        
        /// An array of dictionaries consisting of the data from the completed moves in the session.
        private var moveData: [[String: Int]] = []
        
        /**
         Initialises the SummaryView
         
         - Parameters:
            - completedMoves: Array of completed moves
            - moveData: Array of dictionaries consisting of data of completed moves
         */
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
        
        /**
         Creates a row in the `SummaryView` for each exercise completed
         
         - Parameters:
            - side: An integer value to determine the completed exercise's side
            - totalReps: Total number of reps of the completed exercise
            - completedReps: Number of reps completed for the completed exercise
            - totalSets: Total number of sets of the completed exercise
            - completedSets: Number of sets completed for the completed exercise
         
         - Returns: A row consisting of the data for the completed exercise
         */
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
                    HStack {
                        Spacer(minLength: 5)

                        VStack {
                            VStack (alignment: .leading) {
                                Text("Side Chosen")
                                    .font(.system(size: 16))
                                    .padding(.bottom)
                                Text(sideText)
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                                    
                            }
                            .padding(5)
                            .frame(width: 90, alignment: .leading)

                        }
                        .frame(width: 105, height: 105)
                        .background(Color("Yellow2"))
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        VStack {
                            VStack (alignment: .leading) {
                                Text("Sets Completed")
                                    .font(.system(size: 16))
                                    .padding(.bottom)
                                Text("\(completedSets)/\(totalSets)")
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                            }
                            .padding(5)
                            .frame(width: 90, alignment: .leading)
                        }
                        .frame(width: 105, height: 105)
                        .background(Color("BlueGray"))
                        .cornerRadius(10)

                        Spacer()
                        
                        VStack {
                            VStack (alignment: .leading) {
                                Text("Reps Completed")
                                    .font(.system(size: 16))
                                    .padding(.bottom)
                                Text("\(completedReps)/\(totalReps)")
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                            }
                            .padding(5)
                            .frame(width: 90, alignment: .leading)
                            
                        }
                        .frame(width: 105, height: 105)
                        .background(Color("Gray4"))
                        .cornerRadius(10)
                        
                        Spacer(minLength: 5)
                    }
                }
            }
            return body
        }
        
        }
        
    /// Resets the State Machines for all Moves in the list.
    ///
    /// - Parameters:
    ///     - moves: List of Moves to be reset
    func resetAll(moves: [DraggableMove]) {
        for move in moves {
            move.move.resetStateMachine()
        }
    }
    
    /// Gets the scrolling Title Text.
    ///
    /// Right now this is mainly for debugging purposes to identify which Move is currently active.
    ///
    /// - Returns:
    ///     -   Scrolling title to be displayed
    func getTitleText() -> String {
        if currentMoveIndex + 1 > moves.count {
            return "Move Completed!"
        } else {
            return moves[currentMoveIndex].move.name
        }
    }
        
    /// Runs all terminating functions relevant to the Move session.
    func didDismiss() {
        presentationMode.wrappedValue.dismiss()
        CameraService.terminate()
        AudioManager.stopAll()
        UINavigationBar.appearance().backgroundColor = .white
    }
    
    /// Sets the exerciseCompleted flag to true in all of the moves in the list.
    ///
    /// This is used to consider exercises that were left prematurely as completed as well.
    ///
    /// - Parameters:
    ///     - moves: List of moves to consider complete
    func completeAllExercises(moves: [DraggableMove]) {
        for move in moves {
            move.move.getShared().exerciseCompleted = true
        }
    }
    
    /// Checks if the current Move session is completed.
    func finished() -> Bool {
        return currentMoveIndex + 1 > moves.count
    }
    
    @ViewBuilder
    func getMove(id: Int) -> some View {
        switch(id) {
        case BicepsFlexionModel().id:
            BicepsFlexionView()
            
        case BandedRotationModel().id:
            BandedRotationView()
        
        case PosteriorCapsuleStretchModel().id:
            PosteriorCapsuleStretchView()
            
        case ExternalRotationWithResistanceBandModel().id:
            ExternalRotationWithResistanceBandView()
            
        case InternalRotationWithResistanceBandModel().id:
            InternalRotationWithResistanceBandView()
            
        case ShoulderAbductionModel().id:
            ShoulderAbductionView()
            
        case ShoulderFlexionModel().id:
            ShoulderFlexionView()
            
        case ShoulderExtensionModel().id:
            ShoulderExtensionView()
            
        case ShoulderHorizontalAbductionModel().id:
            ShoulderHorizontalAbductionView()
            
        case PosteriorCapsuleStretchModel().id:
            PosteriorCapsuleStretchView()
            
        case ExternalRotationWithResistanceBandModel().id:
            ExternalRotationWithResistanceBandView()
            
            
        // Knee Exercise
        case StandingKneeBendModel().id:
            StandingKneeBendView()

        case AssistedKneeFlexionModel().id:
            AssistedKneeFlexionView()
            
        case AssistedKneeExtensionModel().id:
            AssistedKneeExtensionView()
            
        default:
            PosteriorCapsuleStretchView()
        }
    }
}
