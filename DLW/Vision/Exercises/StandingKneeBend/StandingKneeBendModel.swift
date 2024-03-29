import SwiftUI
import GameplayKit
import AVFoundation

/// The model for Hip Knee Flexion exercise.
class StandingKneeBendModel: Move {
    
    /// Singleton instance of `StandingKneeBendModel`.
    static var shared: StandingKneeBendModel = StandingKneeBendModel()
    
    /// The array of timers for the instance of `StandingKneeBendModel`.
    static var sharedTimers: [Timer] = []
    
    /// Number of repetitions for the exercise
    static public var repetitions: Int = 1
    
    /// The number of sets.
    static public var sets: Int = 1
    
    /// The maximum duration of a repetition.
    static public var repetitionDuration: Float = 5
    
    /// Instance Variable - The name of the state that the model is currently in.
    @Published var currentStateDescription: String = StandingKneeBendModel.InitialState().description
    
    /// Instance Variable - Number of repetitions remaining.
    @Published var remainingRepetitions: Int = repetitions
    
    /// Instance Variable - The last acceptable frame's angle recorded.
    @Published var lastAngle: Double = 0

    /// Instance Variable - The number of frames the user spends in a single angle.
    @Published var currentAngleFrames: Int = 0
    
    /// Instance Variable - The remaining number of sets to be completed.
    @Published var remainingSets: Int = sets
    
    /// Instance Variable - The angle buffer that a user's angle has to stay within to consider the user to not be moving.
    @Published var leeway: Double = 1

    /// Instance Variable - The count for the number of frames in the calibration state. Used to delay the calibration state.
    @Published var calibrationFrames: Int = 0
    
    // Timer
    /// Instance Variable - The time remaining for the repetition.
    @Published var repetitionDurationLeft: Float = repetitionDuration
    
    /**
     The overriden function to enter a particular state.
     
     - Parameters:
        - stateClass - The state to be entered
     */
    @discardableResult override func enter(_ stateClass: AnyClass) -> Bool {
        let res = super.enter(stateClass)
        if res {
            currentStateDescription = currentState!.description
        }
        return res
    }
    
    private var updateCount: Int = 0
    
    /**
     Initialises the model.
     
     Uses the `Move` parent class' initialiser to initialise the model. It also makes the model enter the initial state.
     */
    init() {
        let gifImages = createAnimateArray(for: "PosteriorCapsuleStretch-")
      
        super.init(
            states: states,
            thisId: 10,
            thisName: "Standing Knee Bend",
            thisType: 1,
            thisImage: gifImages,
            totalSets: StandingKneeBendModel.sets,
            totalRepetitions: (StandingKneeBendModel.repetitions * StandingKneeBendModel.sets),
            bufferInterval: 10,
            setCompletedInterval: 10
        )
        timerLoop()
        self.enter(StandingKneeBendModel.InitialState.self)
    }
    
    /// Function to reset the state machine back to the initial state.
    override func resetStateMachine() {
        StandingKneeBendModel.resetSharedStateMachine()
    }
    
    /// Getter function to get the singleton instance variable of the model.
    override func getShared() -> Move {
        return StandingKneeBendModel.shared
    }
    
    /// Resets the singleton instance of the model.
    private static func resetSharedStateMachine() {
        shared = StandingKneeBendModel()
    }
    
    /// Invalidates all timers that has been ran in the exercise.
    static func invalidateAllTimers() {
        for timer in sharedTimers {
            timer.invalidate()
        }
    }
    
    /// Function to update the current side to the left side.
    func updateToLeftSide() {
        self.currentSide = Side.left
    }
    
    /// Creates a timer to be played when a model gets initialised.
    func timerLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            StandingKneeBendModel.sharedTimers.append(timer)
            if self.updateCount == 20 {
                timer.invalidate()
            }
            self.updateCount += 1
        }
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    /// All the states in the model's state machine.
    ///
    /// Please add any additional states which you have created here.
    private var states: [GKState] = [
        InitialState(),
        CalibrationState(),
        StartState(),
        InPositionState(),
        RepetitionState(),
        RepetitionInitialState(),
        RepetitionInProgressState(),
        RepetitionCompletedState(),
        ExerciseEndState()
    ]

    /// The state which shows the title screen and the "Starting Exercise..." screen.
    class InitialState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
        override func isValidNextState(_ state : AnyClass) -> Bool {
            switch state {
            case is CalibrationState.Type:
                return true
            default:
                return false
            }
        }
        /// The description of the initial state.
        override var description: String {
            get {
                return "StandingKneeBendInitial"
            }
        }
    }

    /// The state which checks if enough of the user's landmarks are within the frame.
    class CalibrationState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
        override func isValidNextState(_ state : AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            case is StartState.Type:
                return true
            default:
                return false
            }
        }
        /// This function outlines the actions to be undertaken upon entry of the calibration state.
        override func didEnter(from: GKState?) {
            StandingKneeBendModel.invalidateAllTimers()
            AudioManager.speakText(text: "Ensure that your entire leg can be seen in the frame.")
            StandingKneeBendModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the calibration state.
        override var description: String {
            get {
                return "StandingKneeBendCalibration"
            }
        }
    }
    
    /// The state which prompts users to get into the starting position of the repetition.
    class StartState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
        override func isValidNextState(_ state : AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            case is InPositionState.Type:
                return true
            case is RepetitionInitialState.Type:
                return true
            default:
                return false
            }
        }
        /// This function outlines the actions to be undertaken upon entry of the start state.
        override func didEnter(from: GKState?) {
            let standingKneeBendModel = StandingKneeBendModel.shared
            let text: String
            
            switch(standingKneeBendModel.side) {
            case .left:
                text = "Turn 90 degrees such that your left leg is facing the camera and hold onto a support infront of you."
                break
            case .right:
                text = "Turn 90 degrees such that your right leg is facing the camera and hold onto a support infront of you."
                break
            case .both:
                if standingKneeBendModel.currentSide == .left {
                    if standingKneeBendModel.firstLeftRepetition {
                        text = "Now turn to the other side, ensuring that your left leg is facing the camera."
                    } else {
                        text = "Turn 90 degrees such that your left leg is facing the camera and hold onto a support infront of you."
                    }
                } else {
                    text = "Turn 90 degrees such that your right leg is facing the camera and hold onto a support infront of you."
                }
                break
            default:
                text = "Turn 90 degrees such that your right leg is facing the camera and hold onto a support infront of you."
            }
            
            AudioManager.speakText(text: text)
            standingKneeBendModel.audioLastPlayedTime = Date.now
        }
        /// Description of the start state.
        override var description: String {
            get {
                return "StandingKneeBendStart"
            }
        }
    }
    
    /// The state that checks if the user is in the correct start position for the repetition.
    class InPositionState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
        override func isValidNextState(_ state: AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            case is RepetitionState.Type:
                return true
            default:
                return false
            }
        }
        /// This function outlines the actions to be undertaken upon entry of the inPosition state.
        override func didEnter(from: GKState?) {
            if shared.firstRepetition {
                AudioManager.speakText(text: TextToSpeech.exerciseIsStarting)
                StandingKneeBendModel.shared.audioLastPlayedTime = Date.now
            }
        }
        /// Description of the inPositionState.
        override var description: String {
            get {
                return "StandingKneeBendInPosition"
            }
        }
    }

    /// The state which checks if there are still repetitions or sets to be completed.
    class RepetitionState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
        ///
        /// Transits to repetitionInitialState if there are repetitions to be completed, and ExerciseEnd state if there are no more repetitions to be completed.
        override func isValidNextState(_ state: AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            case is StartState.Type:
                return true
            case is RepetitionInitialState.Type:
                return true
            case is ExerciseEndState.Type:
                return true
            case is RepetitionCompletedState.Type:
                return true
            default:
                return false
            }
        }
        /// Description of the repetition state.
        override var description: String {
            get {
                return "StandingKneeBendRepetition"
            }
        }
    }

    /// The state which checks if the user has started the repetition.
    class RepetitionInitialState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
        override func isValidNextState(_ state: AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            case is RepetitionInProgressState.Type:
                return true
            case is ExerciseEndState.Type:
                return true
            case is RepetitionCompletedState.Type:
                return true
            default:
                return false
            }
        }
        /// This function outlines the actions to be undertaken upon entry of the repetitionInitial state.
        override func didEnter(from: GKState?) {
            let text: String
            let standingKneeBendModel = StandingKneeBendModel.shared
            if standingKneeBendModel.side == .left || (standingKneeBendModel.currentSide == .left && standingKneeBendModel.side == .both) {
                text = "Bend your left knee to about 90 degrees."
            } else {
                text = "Bend your right knee to about 90 degrees."
            }
            AudioManager.speakText(text: text)
            StandingKneeBendModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionInitial state.
        override var description: String {
            get {
                return "StandingKneeBendRepetitionInitial"
            }
        }
    }

    /// The class which checks if the repetition is being done correctly.
    class RepetitionInProgressState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
        override func isValidNextState(_ state: AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            case is RepetitionCompletedState.Type:
                return true
            default:
                return false
            }
        }
        /// This function outlines the actions to be undertaken upon entry of the repetitionInProgress state.
        override func didEnter(from: GKState?) {
            AudioManager.speakText(text: "Hold this position!")
            StandingKneeBendModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionInProgress state.
        override var description: String {
            get {
                return "StandingKneeBendInProgress"
            }
        }
    }

    /// The state where the user has just completed the repetition.
    class RepetitionCompletedState: GKState {
        override func isValidNextState(_ state: AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            case is RepetitionState.Type:
                return true
            case is StartState.Type:
                return true
            default:
                return false
            }
        }
        /// This function outlines the actions to be undertaken upon entry of the repetitionCompleted state.
        override func didEnter(from: GKState?) {
            let standingKneeBendModel = StandingKneeBendModel.shared
            let text: String
            
            if standingKneeBendModel.goodFrames >= standingKneeBendModel.badFrames {
                text = "Good job! Now relax."
            } else {
                text = "Do better next time! Now relax."
            }
            
            let playAudio = -StandingKneeBendModel.shared.notificationTime.timeIntervalSinceNow > notificationInterval
            
            if playAudio {
                let playerManager = AudioManager.sharedAudioPlayer
                guard let path = Bundle.main.path(forResource: "StretchGoalReached", ofType: "mp3") else {
                    print("Sound file not found")
                    return
                }
                let url = URL(fileURLWithPath: path)
                shared.notificationTime = Date.now
                playerManager.play(url: url)
            }
            
            AudioManager.speakText(text: text)
            StandingKneeBendModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionCompleted state
        override var description: String {
            get {
                return "StandingKneeBendCompleted"
            }
        }
    }
    
    /// The state to signify the end of the exercise.
    class ExerciseEndState: GKState {
        override func isValidNextState(_ state: AnyClass) -> Bool {
            switch state {
            case is InitialState.Type:
                return true
            default:
                return false
            }
        }
        /// This function outlines the actions to be undertaken upon entry of the exercisesEnd state.
        override func didEnter(from: GKState?) {
            let playerManager = AudioManager.sharedAudioPlayer
            guard let path = Bundle.main.path(forResource: "StretchCompletion", ofType: "mp3") else {
                print("Sound file not found")
                return
            }
            let url = URL(fileURLWithPath: path)
            shared.notificationTime = Date.now
            playerManager.play(url: url)
            AudioManager.speakText(text: TextToSpeech.goodExercise)
        }
        /// Description of the exerciseEnd state
        override var description: String {
            get {
                return "StandingKneeBendEnd"
            }
        }
    }
}

