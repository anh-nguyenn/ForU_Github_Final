import SwiftUI

struct ShoulderAbductionView: View {
    @StateObject private var shoulderAbductionModel: ShoulderAbductionModel = ShoulderAbductionModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = ShoulderAbductionModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let shoulderAbductionViewController = ShoulderAbductionViewController()
    
    var body: some View {
        ZStack {
            ShoulderAbductionRepresentableView(shoulderAbductionViewController: shoulderAbductionViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: shoulderAbductionModel)
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
                            ShoulderAbductionModel.repetitions = Int(repetitions)
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
        shoulderAbductionModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = shoulderAbductionModel.currentState
        switch state {
        case state as ShoulderAbductionModel.InitialState: return AnyView(InitialView())
        case state as ShoulderAbductionModel.CalibrationState: return AnyView(CalibrationView())
        case state as ShoulderAbductionModel.StartState: return AnyView(StartView())
        case state as ShoulderAbductionModel.InPositionState: return AnyView(InPositionView())
        case state as ShoulderAbductionModel.RepetitionState: return AnyView(ProgressView())
        case state as ShoulderAbductionModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as ShoulderAbductionModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as ShoulderAbductionModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as ShoulderAbductionModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if shoulderAbductionModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: shoulderAbductionModel,
                                       remainingSets: shoulderAbductionModel.remainingSets,
                                       remainingRepetitions: shoulderAbductionModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: shoulderAbductionModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String
        
        switch(shoulderAbductionModel.side) {
        case .left:
            text = "left"
            break
        case .right:
            text = "right"
            break
        case .both:
            if shoulderAbductionModel.currentSide == .left {
                text = "left"
            } else {
                text = "right"
            }
            break
        default:
            text = "right"
        }
        
        let bodyText: String = "Adjust your position such that your whole body can be seen. Loop resistance band around your \(text) foot and hold the other end of the resistance band securely by your \(text) arm."
        
        let body: some View = VStack {
            BottomInstructionsView(text: bodyText,
                                   move: shoulderAbductionModel,
                                   remainingSets: shoulderAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String
        
        switch(shoulderAbductionModel.side) {
        case .left:
            text = "Keep your left arm straight at the elbow."
            break
        case .right:
            text = "Keep your right arm straight at the elbow."
            break
        case .both:
            if shoulderAbductionModel.currentSide == .left {
                if shoulderAbductionModel.firstLeftRepetition {
                    text = "Now re-adjust your position and keep your left arm straight at the elbow."
                } else {
                    text = "Keep your left arm straight at the elbow."
                }
            } else {
                text = "Keep your right arm straight at the elbow."
            }
            break
        default:
            text = "Keep your right arm straight at the elbow."
        }
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: shoulderAbductionModel,
                                   remainingSets: shoulderAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: shoulderAbductionModel,
                                remainingDuration: shoulderAbductionModel.startTimeLeft,
                                remainingSets: shoulderAbductionModel.remainingSets,
                                remainingRepetitions: shoulderAbductionModel.remainingRepetitions
            )
        }
        return body
    }

    
    func RepetitionInitialView() -> some View {
        let bodyText: String = "Slowly raise the arm out to the side"
        let body: some View = Group {
            BottomInstructionsView(text: bodyText,
                                   move: shoulderAbductionModel,
                                   remainingSets: shoulderAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if shoulderAbductionModel.repetitionIsGood {
            if shoulderAbductionModel.currentAngleFrames < 40 {
                text = "Good job, keep going!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: shoulderAbductionModel,
                                remainingDuration: shoulderAbductionModel.repetitionDurationLeft,
                                remainingSets: shoulderAbductionModel.remainingSets,
                                remainingRepetitions: shoulderAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String = "Good job! Now bring your arm back down slowly and with control."

        if shoulderAbductionModel.setCompleted {
            text = "Set \(ShoulderAbductionModel.sets - shoulderAbductionModel.remainingSets + 1) Completed!"
        } else {
            if (shoulderAbductionModel.isGiveUp){
                text = TextToSpeech.doNotGiveUp
            }
        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: shoulderAbductionModel,
                                   remainingSets: shoulderAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderAbductionModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = ShoulderAbductionModel.repetitions - shoulderAbductionModel.remainingRepetitions
                    if shoulderAbductionModel.side == .left || (shoulderAbductionModel.side == .both && shoulderAbductionModel.currentSide == .left) {
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
                        Text(String(Int(shoulderAbductionModel.transitionTimer)))
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
                BottomInstructionsView(text: shoulderAbductionModel.currentState!.description,
                                       move: shoulderAbductionModel,
                                       remainingSets: shoulderAbductionModel.remainingSets,
                                       remainingRepetitions: shoulderAbductionModel.remainingRepetitions
                )
            }
        }
        return body
    }
    
    func ProgressView() -> some View {
        let body: some View =
        VStack() {
            Spacer()
            VStack {
                VStack (alignment: .center) {
                    HStack {
                        Spacer()
                        VStack (alignment: .center){
                            Text("Reps Left")
                                .font(.system(size: 16))
                            Text(String(shoulderAbductionModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(shoulderAbductionModel.remainingSets))
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
    
    struct ShoulderAbductionRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let shoulderAbductionViewController: ShoulderAbductionViewController
        let shoulderAbductionModel: ShoulderAbductionModel = ShoulderAbductionModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            shoulderAbductionViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(shoulderAbductionViewController.previewLayer)
            shoulderAbductionViewController.previewLayer.frame = viewController.view.bounds
            shoulderAbductionModel.enter(ShoulderAbductionModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageShoulderAbductionWithResistanceBand)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: ShoulderAbductionRepresentableView
            init(_ parent: ShoulderAbductionRepresentableView) {
                self.parent = parent
            }
        }
    }
}
