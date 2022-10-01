//
//  Move.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import GameplayKit


class Move: GKStateMachine, ObservableObject {
    
    // Variables that needs to be initialised by the exercise model
    
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
    
    /// Type of Move.
    ///
    /// 0: Do both sides at the same time
    /// 1:  Can choose affected side
    /// 2: Can choose one side but not both
    var type: Int
    
    /// Gif of the preview Image.
    var image: UIImage
    var smallImage: UIImage
    
    /// The number of seconds between 2 repetitions.
    let bufferInterval: Double
    
    /// The number of seconds between 2 sets.
    let setCompletedInterval: Double
    
    
    // Common variables between the exercise models
    
    /// Minimum interval between notifications.
    static public var notificationInterval: Double = 1
    
    /// Minimum interval between the text to speech audio playing.
    static public var speechInterval: Double = 4
    
    /// The number of second for the timer to countdown at the start of the exercise.
    static public var startTime: Float = 3
    
    /// The image dimension for the gif of the exercise.
    static let instructionImageDimension = getWindowWidth() * 0.40
    
    /// Interval for transitioning between exercises.
    static let transitionTime: Float = 3
    
    /// Checks if the user has been shown the instruction for the move
    @Published var instructed: Bool = false
    
    /// Flag to check if the current exercise is the first exercise in the exercise queue.
    @Published var firstExercise: Bool = true
    
    /// Flag to check if the current exercise has been completed.
    @Published var exerciseCompleted: Bool = false
    
    /// The timer for the transition between exercises for each exercise instance.
    @Published var transitionTimer: Float = transitionTime
    
    /// Flag to check if the transition timer should be active.
    @Published var transitionTimerIsActive: Bool = false
    
    /// Deprecated - The number of good repetitions completed for the exercise.
    @Published var currentGoodCount: Int = 0
    
    /// Deprecated - The number of bad repetitions completed for the exercise.
    @Published var currentBadCount: Int = 0
    
    /// Deprecated - The number of frames which has a pose that is determined to be good. Used to determine if the rep is good or bad.
    @Published var goodFrames: Int = 0
    
    /// Deprecated - The number of frames which has a pose that is determined to be bad. Used to determine if the rep is good or bad.
    @Published var badFrames: Int = 0
    
    /// The affected side chosen for the exercise.
    @Published var side: Side? = nil
    
    /// Instance Variable - The time a notification was last played.
    @Published var notificationTime: Date = Date.now
    
    /// Instance Variable - Flag to determine if the exercise is currently in its first repetition.
    @Published var firstRepetition: Bool = true
    
    /// Instance Variable - The flag to determine if a set is completed.
    @Published var setCompleted: Bool = false
    
    /// Instance Variable - The buffer time between 2 reps or 2 sets.
    @Published var bufferTime: Double = 0
    
    /// Instance Variable - The time remaining before the exercise gets from the inPositionState to repetitionInitialState.
    @Published var startTimeLeft: Float = startTime
    
    /// Instance Variable - The time in which any audio was last played.
    @Published var audioLastPlayedTime = Date.now
    
    /// Instance Variable - Flag to determine if its the first left repetition.
    @Published var firstLeftRepetition: Bool = true
    
    /// Instance Variable - Flag to determine if the current frame's pose is acceptable. Used to display the good or bad message in the repetitionInProgress state.
    @Published var repetitionIsGood = false
    
    /// Instance Variable - The current side the exercise is currently in. Only used when the user chooses the "Both" option for the affected side.
    @Published var currentSide: Side = .right
    
    // Timer
    /// Instance Variable - Flag to determine if the user has stopped doing the exercise midway.
    @Published var isGiveUp: Bool = false
    
    /// Instance Variable - Flag to determine if the repetitionTimer should be activated.
    @Published var isActivated: Bool = false
    
    /// The time in which the last text to speech audio was played.
    var lastSpeechTime: Date = Date.now

    
    // Variables to evaluate the session completed
    
    /// Total number of repetitions to be completed for an exercise.
    var totalRepetitions: Int
    
    /// Total number of sets to be completed for an exercise.
    var totalSets: Int
    
    /// Total number of completed sets for an exercise.
    @Published var completedSets: Int = 0
    
    /// Total number of completed repetitions for an exercise.
    @Published var completedReps: Int = 0
  
    /// Total number of completed repetitions for a session.
    static var finishedReps: Int = 0
    
    /// Total number of repetitions to be completed in a session.
    static var totalReps: Int = 0
    
    /// Side that was chosen for the exercise.
    enum Side: Equatable {
        
        /// Right side affected.
        case right
        
        /// Left side affected.
        case left
        
        /// Both sides are affected.
        case both
    }

    /// Resets the internal State Machine. To be implemented by subclasses.
    func resetStateMachine() {  }

    /// To get the singleton instance of an exercise. To be overridden by subclasses.
    func getShared() -> Move {
        return self
    }
    
    /**
    Sets an exercise to be instructed.
     
     Calling this method would stop the exercise from showing the view with the gif and go into the exercise proper.
     
     - Parameters:
        - firstExercise: Flag that determines if the current exercise is the first exercise in the exercise queue.
     */
    func setInstructed(firstExercise: Bool) {
        getShared().instructed = true
        getShared().transitionTimerIsActive = false
        getShared().firstExercise = firstExercise

    }
    
    /**
    Sets an exercise to not be instructed.
     
     Calling this method would cause the exercise to showing the view with the gif.
     
     - Parameters:
        - firstExercise: Flag that determines if the current exercise is the first exercise in the exercise queue.
     */
    func setNotInstructed(firstExercise: Bool) {
        getShared().instructed = false
        getShared().transitionTimerIsActive = true
        getShared().firstExercise = firstExercise
    }
    
    /**
     Custom initialiser for Move.
     
     - Parameters:
        - states: An array of the states present in the exercise's state machine
        - thisID: The ID of the exercise
        - thisName: The name of the exercise
        - thisType: The type of the exercise
        - image: The images of the gif of the exercise
        - totalSets: The total number of sets to be completed in the exercise.
        - totalRepetitions: The total number of repetitions to be completed in the exercise,
        - bufferInterval: The time interval between 2 repetitions.
        - setCompletedInterval: The time interval between 2 sets.
     */
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

    /// Gets the name of Move.
    ///
    /// - Returns: Name of Move
    func description() -> String {
        return name
    }
}

