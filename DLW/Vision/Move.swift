//
//  Move.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import GameplayKit


class Move: GKStateMachine, ObservableObject {

    /**
     Move unique ID.
     
     Shoulder Exercises
     1: Biceps Flexion with Resistance Band
     2: Banded Rotation with Scapular Retraction
     3: Posterior Capsule Stretch
     4: External Rotation with Resistance Band
     5: Internal Rotation with Resistance Band
     6: Shoulder Abduction with Resistance Band
     7: Shoulder Horizontal Abduction with Resistance Band
     8: External Rotation with Resistance Band
     9: Shoulder Horizontal Abduction with Resistance Band
     
     Knee Exercises
     10: Standing Knee Bend
     11: Assisted Knee Flexion
     12: Assisted Knee Extension
     
    */
    var id: Int
    
    /// Name of the Move.
    var name: String
    
    var type: Int
    
    var image: UIImage
    var smallImage: UIImage
    
    let bufferInterval: Double
    
    let setCompletedInterval: Double
    
    static public var notificationInterval: Double = 1
    
    static public var speechInterval: Double = 4
    
    static public var startTime: Float = 3
    
    static let instructionImageDimension = getWindowWidth() * 0.40
    
    static let transitionTime: Float = 2
    
    @Published var instructed: Bool = false
    
    @Published var firstExercise: Bool = true
    
    @Published var exerciseCompleted: Bool = false
    
    @Published var transitionTimer: Float = transitionTime
    
    @Published var transitionTimerIsActive: Bool = false
    
    @Published var currentGoodCount: Int = 0
    
    @Published var currentBadCount: Int = 0
    
    @Published var goodFrames: Int = 0
    
    @Published var badFrames: Int = 0
    
    @Published var side: Side? = nil
    
    @Published var notificationTime: Date = Date.now
    
    @Published var firstRepetition: Bool = true
    
    @Published var setCompleted: Bool = false
    
    @Published var bufferTime: Double = 0
    
    @Published var startTimeLeft: Float = startTime
    
    @Published var audioLastPlayedTime = Date.now
    
    @Published var firstLeftRepetition: Bool = true
    
    @Published var repetitionIsGood = false
    
    @Published var currentSide: Side = .right
    
    @Published var isGiveUp: Bool = false
    
    @Published var isActivated: Bool = false
    
    var lastSpeechTime: Date = Date.now

    var totalRepetitions: Int
    
    var totalSets: Int
    
    @Published var completedSets: Int = 0
    
    @Published var completedReps: Int = 0
  
    static var finishedReps: Int = 0
    
    static var totalReps: Int = 0
    
    enum Side: Equatable {
        case right
        
        case left
        
        case both
    }

    func resetStateMachine() {  }

    func getShared() -> Move {
        return self
    }

    func setInstructed(firstExercise: Bool) {
        getShared().instructed = true
        getShared().transitionTimerIsActive = false
        getShared().firstExercise = firstExercise

    }
    
    func setNotInstructed(firstExercise: Bool) {
        getShared().instructed = false
        getShared().transitionTimerIsActive = true
        getShared().firstExercise = firstExercise
    }
    
    init(states: [GKState], thisId: Int, thisName: String, thisType: Int, thisImage: [UIImage], totalSets: Int, totalRepetitions: Int, bufferInterval: Double, setCompletedInterval: Double) {
        
        let smallGif = thisImage.map { resizeAnimatedGif(gif: $0, width: 50, height: 50) }
        let smallImage = UIImage.animatedImage(with: smallGif, duration: 1.5)!
        let image = UIImage.animatedImage(with: thisImage, duration: 1.5)!

        self.id = thisId
        self.name = thisName
        self.type =  thisType
        self.image = image
        self.smallImage = smallImage
        self.totalSets = totalSets
        self.totalRepetitions = totalRepetitions
        self.bufferInterval = bufferInterval
        self.setCompletedInterval = setCompletedInterval
        super.init(states: states)
    }

    func description() -> String {
        return name
    }
}

