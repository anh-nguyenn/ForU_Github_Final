import SwiftUI

struct ShoulderExtensionView: View {
    @StateObject private var shoulderExtensionModel: ShoulderExtensionModel = ShoulderExtensionModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = ShoulderExtensionModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let shoulderExtensionViewController = ShoulderExtensionViewController()
    
    var body: some View {
        ZStack {
            ShoulderExtensionRepresentableView(shoulderExtensionViewController: shoulderExtensionViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: shoulderExtensionModel)
                self.content
                Spacer()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea()
        .statusBar(hidden: false)
        .preferredColorScheme(.light)
    }
    
    struct SettingsView: View {
        @Binding var repetitions: Float
        @State private var isEditing: Bool = false
        
        var body: some View {
            HStack{
                VStack{
                    Text("Repetitions:")
                        .padding()
                    Spacer()
                }
                VStack {
                    Slider(
                        value: $repetitions,
                        in: 1...5,
                        step: 1,
                        onEditingChanged: { editing in
                            isEditing = editing
                            ShoulderExtensionModel.repetitions = Int(repetitions)
                            saveSettings()
                        }
                    )
                    .padding()
                    Text("\(Int(repetitions))")
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding()
        }
        func saveSettings() {

        }
    }
    
    func didDismiss() {
        isCustomCameraViewPresented = false
        presentationMode.wrappedValue.dismiss()
        shoulderExtensionModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = shoulderExtensionModel.currentState
        switch state {
        case state as ShoulderExtensionModel.InitialState: return AnyView(InitialView())
        case state as ShoulderExtensionModel.CalibrationState: return AnyView(CalibrationView())
        case state as ShoulderExtensionModel.StartState: return AnyView(StartView())
        case state as ShoulderExtensionModel.InPositionState: return AnyView(InPositionView())
        case state as ShoulderExtensionModel.RepetitionState: return AnyView(ProgressView())
        case state as ShoulderExtensionModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as ShoulderExtensionModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as ShoulderExtensionModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as ShoulderExtensionModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if shoulderExtensionModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: shoulderExtensionModel,
                                       remainingSets: shoulderExtensionModel.remainingSets,
                                       remainingRepetitions: shoulderExtensionModel.remainingRepetitions
                )
                
            } else {
                PreMoveInstructonView(move: shoulderExtensionModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text = "Tie resistance band higher up onto secure structure, and adjust your position such that your affected shoulder and arm can be seen."
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: shoulderExtensionModel,
                                   remainingSets: shoulderExtensionModel.remainingSets,
                                   remainingRepetitions: shoulderExtensionModel.remainingRepetitions
            )
            
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String
        
        switch(shoulderExtensionModel.side) {
        case .left:
            text = "While facing 90 degrees to the right, hold the other end of the band in left arm and raise your arm to shoulder height."
            break
        case .right:
            text = "While facing 90 degrees to the left, hold the other end of the band in right arm and raise your arm to shoulder height."
            break
        case .both:
            if shoulderExtensionModel.currentSide == .left {
                if shoulderExtensionModel.firstLeftRepetition {
                    text = "Now face the other side, hold the other end of the band in left arm and raise your arm to shoulder height."
                }
                else {
                    text = "While facing 90 degrees to the right, hold the other end of the band in left arm and raise your arm to shoulder height."
                }
            } else {
                text = "While facing 90 degrees to the left, hold the other end of the band in right arm and raise your arm to shoulder height."
            }
            break
        default:
            text = "While facing 90 degrees to the left, hold the other end of the band in right arm and raise your arm to shoulder height."
        }
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: shoulderExtensionModel,
                                   remainingSets: shoulderExtensionModel.remainingSets,
                                   remainingRepetitions: shoulderExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: shoulderExtensionModel,
                                remainingDuration: shoulderExtensionModel.startTimeLeft,
                                remainingSets: shoulderExtensionModel.remainingSets,
                                remainingRepetitions: shoulderExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let bodyText: String = "Slowly pull arm down and backwards"
        let body: some View = Group {
            BottomInstructionsView(text: bodyText,
                                   move: shoulderExtensionModel,
                                   remainingSets: shoulderExtensionModel.remainingSets,
                                   remainingRepetitions: shoulderExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if shoulderExtensionModel.repetitionIsGood {
            if shoulderExtensionModel.currentAngleFrames < 30 {
                text = "Good job, keep going!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: shoulderExtensionModel,
                                remainingDuration: shoulderExtensionModel.repetitionDurationLeft,
                                remainingSets: shoulderExtensionModel.remainingSets,
                                remainingRepetitions: shoulderExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String = "Good job! Now slowly bring your arm back up with control."

        if shoulderExtensionModel.setCompleted {
            text = "Set \(ShoulderExtensionModel.sets - shoulderExtensionModel.remainingSets + 1) Completed!"
        } else {
            if (shoulderExtensionModel.isGiveUp){
                text = TextToSpeech.doNotGiveUp
            }
        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: shoulderExtensionModel,
                                   remainingSets: shoulderExtensionModel.remainingSets,
                                   remainingRepetitions: shoulderExtensionModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = ShoulderExtensionModel.repetitions - shoulderExtensionModel.remainingRepetitions
                    if shoulderExtensionModel.side == .left || (shoulderExtensionModel.side == .both && shoulderExtensionModel.currentSide == .left) {
                    } else {
                    }
                }
        }
        return body
    }
    
    func EndView() -> some View {
        let body: some View =
        VStack{
            Spacer()
            VStack {
                VStack (alignment: .center) {
                    HStack {
                        Spacer()
                        Text("Stretch Completed!")
                            .font(.system(size: 20))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text(String(Int(shoulderExtensionModel.transitionTimer)))
                            .font(.system(size: 22))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .padding()
            }
            .background(Color("Yellow2"))
            .cornerRadius(20)
            .padding()
        }
        .padding(.bottom)
        .onAppear {
        }
        return body
    }
    
    func DefaultView() -> some View {
        let body: some View = ZStack {
            VStack {
                BottomInstructionsView(text: shoulderExtensionModel.currentState!.description,
                                       move: shoulderExtensionModel,
                                       remainingSets: shoulderExtensionModel.remainingSets,
                                       remainingRepetitions: shoulderExtensionModel.remainingRepetitions
                )
            }
        }
        return body
    }
    
    func ProgressView() -> some View {
        let body: some View =
            VStack {
                Spacer()
                VStack {
                    VStack (alignment: .center) {
                        HStack {
                            Spacer()
                            VStack (alignment: .center){
                                Text("Reps Left")
                                    .font(.system(size: 16))
                                Text(String(shoulderExtensionModel.remainingRepetitions))
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            Image("VerticalDivider")
                            Spacer()
                            VStack (alignment: .center){
                                Text("Sets Left")
                                    .font(.system(size: 16))
                                Text(String(shoulderExtensionModel.remainingSets))
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                }
                .cornerRadius(10)
                .background(Color("Yellow2"))
            }
        return body
    }
    
    struct ShoulderExtensionRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let shoulderExtensionViewController: ShoulderExtensionViewController
        let shoulderExtensionModel: ShoulderExtensionModel = ShoulderExtensionModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            shoulderExtensionViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(shoulderExtensionViewController.previewLayer)
            shoulderExtensionViewController.previewLayer.frame = viewController.view.bounds
            shoulderExtensionModel.enter(ShoulderExtensionModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageShoulderExtensionWithResistanceBand)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: ShoulderExtensionRepresentableView
            init(_ parent: ShoulderExtensionRepresentableView) {
                self.parent = parent
            }
        }
    }
}
