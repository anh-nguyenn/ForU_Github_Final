import SwiftUI
import GameplayKit
import AVFoundation

/// The model for Banded Rotation with Scapular Retraction exercise.
class BandedRotationModel: Move {
    
    /// Singleton instance of `BandedRotationModel`
    static var shared: BandedRotationModel = BandedRotationModel()
    
    /// The array of timers for the instance of `BandedRotationModel`
    static var sharedTimers: [Timer] = []
    
    /// Number of repetitions for the exercise
    static public var repetitions: Int = 3
    
    /// The number of sets.
    static public var sets: Int = 3
    
    /// The maximum duration of a repetition.
    static public var repetitionDuration: Float = 10
    
    @Published var calibrationFrames: Int = 0
    
    /// Instance Variable - The name of the state that the model is currently in.
    @Published var currentStateDescription: String = BandedRotationModel.InitialState().description
    
    /// Instance Variable - Number of repetitions remaining.
    @Published var remainingRepetitions: Int = repetitions
    
    /// Instance Variable - Ratio between the horizontal distance from the left elbow to the left wrist to the vertical distance from the left elbow to left shoulder.
    @Published var lastLeftRatio: Double = 0
    
    /// Instance Variable - Ratio between the horizontal distance from the right elbow to the right wrist to the vertical distance from the right elbow to right shoulder.
    @Published var lastRightRatio: Double = 0
    
    /// Instance Variable - The number of frames the user spends in a single angle.
    @Published var currentAngleFrames: Int = 0
    
    /// Instance Variable - The remaining number of sets to be completed.
    @Published var remainingSets: Int = sets
    
    /// Instance Variable - The ratio buffer that a user's ratio has to stay within to consider the user to not be moving.
    @Published var leeway: Double = 1.25
    
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
            thisId: 2,
            thisName: "Banded Rotation with Scapular Retraction",
            thisType: 0,
            thisImage: gifImages,
            totalSets: BandedRotationModel.sets,
            totalRepetitions: (BandedRotationModel.repetitions * BandedRotationModel.sets),
            bufferInterval: 15,
            setCompletedInterval: 15
        )
        timerLoop()
        self.enter(BandedRotationModel.InitialState.self)
        
    }
    
    /// Function to reset the state machine back to the initial state.
    override func resetStateMachine() {
        BandedRotationModel.resetSharedStateMachine()
    }
    
    /// Getter function to get the singleton instance variable of the model.
    override func getShared() -> Move {
        return BandedRotationModel.shared
    }
    
    /// Resets the singleton instance of the model.
    private static func resetSharedStateMachine() {
        shared = BandedRotationModel()
    }
    
    /// Invalidates all timers that has been ran in the exercise.
    static func invalidateAllTimers() {
        for timer in sharedTimers {
            timer.invalidate()
        }
    }
    
    /// Creates a timer to be played when a model gets initialised.
    func timerLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            BandedRotationModel.sharedTimers.append(timer)
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
                return "BandedRotationInitial"
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
            BandedRotationModel.invalidateAllTimers()
            AudioManager.speakText(text: "Face the camera with your shoulders and arms visible.")
            BandedRotationModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the calibration state.
        override var description: String {
            get {
                return "BandedRotationCalibration"
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
            let model = BandedRotationModel.shared
            let text: String = "While seated, bend your elbows and wrap a resistance band around both hands."
            AudioManager.speakText(text: text)
            model.audioLastPlayedTime = Date.now
        }
        /// Description of the start state.
        override var description: String {
            get {
                return "BandedRotationStart"
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
                BandedRotationModel.shared.audioLastPlayedTime = Date.now
            }
        }
        /// Description of the inPositionState.
        override var description: String {
            get {
                return "BandedRotationInPosition"
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
                return "BandedRotationRepetition"
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
            let text: String = "With both elbows in contact with your body, rotate both your arms outwards."
            AudioManager.speakText(text: text)
            BandedRotationModel.shared.audioLastPlayedTime = Date.now

        }
        /// Description of the repetitionInitial state.
        override var description: String {
            get {
                return "BandedRotationRepetitionInitial"
            }
        }
    }
    
    /// The class which checks if the repetition is being done correctly.
    class RepetitionInProgressState: GKState {
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
            let text: String = "Stretch outwards as much as you can."
            AudioManager.speakText(text: text)
            BandedRotationModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionInProgress state.
        override var description: String {
            get {
                return "BandedRotationInProgress"
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
            let bandedRotationModel = BandedRotationModel.shared
            var text : String = "Good job! Now bring your arms back to the middle slowly and with control."
            
            if bandedRotationModel.setCompleted {
                text = "Set \(BandedRotationModel.sets - bandedRotationModel.remainingSets + 1) Completed!"
            } else {
                if bandedRotationModel.isGiveUp {
                    text = TextToSpeech.doNotGiveUp
                }
            }
            
            let playAudio = -BandedRotationModel.shared.notificationTime.timeIntervalSinceNow > notificationInterval
            
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
            bandedRotationModel.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionCompleted state
        override var description: String {
            get {
                return "BandedRotationCompleted"
            }
        }
    }
    
    /// The state to signify the end of the exercise.
    class ExerciseEndState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
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
                return "BandedRotationEnd"
            }
        }
    }
}
