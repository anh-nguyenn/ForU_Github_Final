import SwiftUI
import GameplayKit
import AVFoundation

/// The model for Shoulder Horizontal Abduction with Resistance Band exercise.
class ShoulderHorizontalAbductionModel: Move {
    
    /// Singleton instance of `ShoulderHorizontalAbductionModel`
    static var shared: ShoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel()
    
    /// The array of timers for the instance of `ShoulderHorizontalAbductionModel`
    static var sharedTimers: [Timer] = []
    
    /// Number of repetitions for the exercise
    static public var repetitions: Int = 1
    
    /// The number of sets.
    static public var sets: Int = 1
    
    /// The maximum duration of a repetition.
    static public var repetitionDuration: Float = 10
    
    /// Instance Variable - The count for the number of frames in the calibration state. Used to delay the calibration state.
    @Published var calibrationFrames: Int = 0
    
    /// Instance Variable - The name of the state that the model is currently in.
    @Published var currentStateDescription: String = ShoulderHorizontalAbductionModel.InitialState().description
    
    /// Instance Variable - Number of repetitions remaining.
    @Published var remainingRepetitions: Int = repetitions
    
    /// Instance Variable - The previous accepted frame's horizontal distance on the right side.
    @Published var lastRightXDistance: Double = 0
    
    /// Instance Variable - The previous accepted frame's horizontal distance on the left side.
    @Published var lastLeftXDistance: Double = 0

    /// Instance Variable - The number of frames the user spends in a single angle.
    @Published var currentAngleFrames: Int = 0
    
    /// Instance Variable - The remaining number of sets to be completed.
    @Published var remainingSets: Int = sets
    
    /// Instance Variable - The angle buffer that a user's angle has to stay within to consider the user to not be moving.
    @Published var leeway: Double = 0.02
    
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
            thisId: 9,
            thisName: "Shoulder Horizontal Abduction with Resistance Band",
            thisType: 0,
            thisImage: gifImages,
            totalSets: ShoulderHorizontalAbductionModel.sets,
            totalRepetitions: (ShoulderHorizontalAbductionModel.repetitions * ShoulderHorizontalAbductionModel.sets),
            bufferInterval: 12,
            setCompletedInterval: 10
        )
        timerLoop()
        self.enter(ShoulderHorizontalAbductionModel.InitialState.self)
        
    }
    
    /// Function to reset the state machine back to the initial state.
    override func resetStateMachine() {
        ShoulderHorizontalAbductionModel.resetSharedStateMachine()
    }
    
    /// Getter function to get the singleton instance variable of the model.
    override func getShared() -> Move {
        return ShoulderHorizontalAbductionModel.shared
    }
    
    /// Resets the singleton instance of the model.
    private static func resetSharedStateMachine() {
        shared = ShoulderHorizontalAbductionModel()
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
            ShoulderHorizontalAbductionModel.sharedTimers.append(timer)
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
                return "ShoulderHorizontalAbductionInitial"
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
            let text: String = "Face the camera with your shoulders and arms visible at all times and wrap a resistance band around both hands."
            ShoulderHorizontalAbductionModel.invalidateAllTimers()
            AudioManager.speakText(text: text)
            ShoulderHorizontalAbductionModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the calibration state.
        override var description: String {
            get {
                return "ShoulderHorizontalAbductionCalibration"
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
            let text: String = "Keep your arms straight towards the camera."
            
            AudioManager.speakText(text: text)
            ShoulderHorizontalAbductionModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the start state.
        override var description: String {
            get {
                return "ShoulderHorizontalAbductionStart"
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
                ShoulderHorizontalAbductionModel.shared.audioLastPlayedTime = Date.now
            }
        }
        /// Description of the inPositionState.
        override var description: String {
            get {
                return "ShoulderHorizontalAbductionInPosition"
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
                return "ShoulderHorizontalAbductionRepetition"
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
            AudioManager.speakText(text: "Slowly rotate both your arms outwards.")
            ShoulderHorizontalAbductionModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionInitial state.
        override var description: String {
            get {
                return "ShoulderHorizontalAbductionRepetitionInitial"
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
            let text: String = "Stretch outwards as much as you can."
            
            AudioManager.speakText(text: text)
            ShoulderHorizontalAbductionModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionInitial state.
        override var description: String {
            get {
                return "ShoulderHorizontalAbductionInProgress"
            }
        }
    }

    /// The state where the user has just completed the repetition.
    class RepetitionCompletedState: GKState {
        /// The valid next states that this state. Please add any states that the state can travel to here.
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
            let shoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel.shared
            var text: String = "Good job. Now bring your arm back to the middle slowly and with control."
            
            if shoulderHorizontalAbductionModel.setCompleted {
                text = "Set \(ShoulderHorizontalAbductionModel.sets - shoulderHorizontalAbductionModel.remainingSets + 1) completed."
            } else {
                if (shoulderHorizontalAbductionModel.isGiveUp)
                {
                    text = TextToSpeech.doNotGiveUp
                }
            }
            
            let playAudio = -ShoulderHorizontalAbductionModel.shared.notificationTime.timeIntervalSinceNow > ShoulderHorizontalAbductionModel.notificationInterval
            
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
            ShoulderHorizontalAbductionModel.shared.audioLastPlayedTime = Date.now
        }
        /// Description of the repetitionCompleted state
        override var description: String {
            get {
                return "ShoulderHorizontalAbductionCompleted"
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
                return "ShoulderHorizontalAbductionEnd"
            }
        }
    }
    
}
