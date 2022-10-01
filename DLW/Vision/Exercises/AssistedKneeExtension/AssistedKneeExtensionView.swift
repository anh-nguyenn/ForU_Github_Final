import SwiftUI

struct AssistedKneeExtensionView: View {
    @StateObject private var assistedKneeExtensionModel: AssistedKneeExtensionModel = AssistedKneeExtensionModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = AssistedKneeExtensionModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let assistedKneeExtensionViewController = AssistedKneeExtensionViewController()
    
    var body: some View {
        ZStack {
            AssistedKneeExtensionRepresentableView(assistedKneeExtensionViewController: assistedKneeExtensionViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: assistedKneeExtensionModel)
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
                            AssistedKneeExtensionModel.repetitions = Int(repetitions)
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
        assistedKneeExtensionModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = assistedKneeExtensionModel.currentState
        switch state {
        case state as AssistedKneeExtensionModel.InitialState: return AnyView(InitialView())
        case state as AssistedKneeExtensionModel.CalibrationState: return AnyView(CalibrationView())
        case state as AssistedKneeExtensionModel.StartState: return AnyView(StartView())
        case state as AssistedKneeExtensionModel.InPositionState: return AnyView(InPositionView())
        case state as AssistedKneeExtensionModel.RepetitionState: return AnyView(ProgressView())
        case state as AssistedKneeExtensionModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as AssistedKneeExtensionModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as AssistedKneeExtensionModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as AssistedKneeExtensionModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if assistedKneeExtensionModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: assistedKneeExtensionModel,
                                       remainingSets: assistedKneeExtensionModel.remainingSets,
                                       remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: assistedKneeExtensionModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String = "While seated, ensure that your entire injured leg can be seen in the frame."
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: assistedKneeExtensionModel,
                                   remainingSets: assistedKneeExtensionModel.remainingSets,
                                   remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String
        
        switch(assistedKneeExtensionModel.side) {
        case .left:
            text = "Turn 90 degrees such that your left leg is facing the camera and bent at 90 degrees. Place your right leg behind your left leg."
            break
        case .right:
            text = "Turn 90 degrees such that your right leg is facing the camera and bent at 90 degrees. Place your left leg behind your right leg."
            break
        case .both:
            if assistedKneeExtensionModel.currentSide == .left {
                if assistedKneeExtensionModel.firstLeftRepetition {
                    text = "Now turn to the other side such that your left leg is facing the camera and bent at 90 degrees. Place your right leg behind your left leg."
                } else {
                    text = "Turn 90 degrees such that your left leg is facing the camera and bent at 90 degrees. Place your right leg behind your left leg."
                }
            } else {
                text = "Turn 90 degrees such that your right leg is facing the camera and bent at 90 degrees. Place your left leg behind your right leg."
            }
            break
        default:
            text = "Turn 90 degrees such that your right leg is facing the camera and bent at 90 degrees. Place your left leg behind your right leg."
        }
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: assistedKneeExtensionModel,
                                   remainingSets: assistedKneeExtensionModel.remainingSets,
                                   remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: assistedKneeExtensionModel,
                                remainingDuration: assistedKneeExtensionModel.startTimeLeft,
                                remainingSets: assistedKneeExtensionModel.remainingSets,
                                remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let text: String
        if assistedKneeExtensionModel.side == .left || (assistedKneeExtensionModel.currentSide == .left && assistedKneeExtensionModel.side == .both) {
            text = "Use your right leg to push your left leg upwards."
        } else {
            text = "Use your left leg to push your right leg upwards."
        }
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: assistedKneeExtensionModel,
                                   remainingSets: assistedKneeExtensionModel.remainingSets,
                                   remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if assistedKneeExtensionModel.repetitionIsGood {
            if assistedKneeExtensionModel.currentAngleFrames < 40 {
                text = "Good job, keep going!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: assistedKneeExtensionModel,
                                remainingDuration: Float(assistedKneeExtensionModel.repetitionDurationLeft),
                                remainingSets: assistedKneeExtensionModel.remainingSets,
                                remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String = TextToSpeech.goodWithRelax

        if assistedKneeExtensionModel.setCompleted {
            text = "Set \(AssistedKneeExtensionModel.sets - assistedKneeExtensionModel.remainingSets + 1) Completed!"
        } else {
            if assistedKneeExtensionModel.isGiveUp {
                text = TextToSpeech.doNotGiveUp
            }
        }
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: assistedKneeExtensionModel,
                                   remainingSets: assistedKneeExtensionModel.remainingSets,
                                   remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = Int(AssistedKneeExtensionModel.repetitions - assistedKneeExtensionModel.remainingRepetitions)
                    if assistedKneeExtensionModel.side == .left || (assistedKneeExtensionModel.currentSide == .left && assistedKneeExtensionModel.side == .both) {
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
                        Text(String(Int(assistedKneeExtensionModel.transitionTimer)))
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
                BottomInstructionsView(text: assistedKneeExtensionModel.currentState!.description,
                                       move: assistedKneeExtensionModel,
                                       remainingSets: assistedKneeExtensionModel.remainingSets,
                                       remainingRepetitions: assistedKneeExtensionModel.remainingRepetitions
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
                            Text(String(assistedKneeExtensionModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(assistedKneeExtensionModel.remainingSets))
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
    
    struct AssistedKneeExtensionRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let assistedKneeExtensionViewController: AssistedKneeExtensionViewController
        let assistedKneeExtensionModel: AssistedKneeExtensionModel = AssistedKneeExtensionModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            assistedKneeExtensionViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(assistedKneeExtensionViewController.previewLayer)
            assistedKneeExtensionViewController.previewLayer.frame = viewController.view.bounds
            assistedKneeExtensionModel.enter(AssistedKneeExtensionModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageAssistedKneeExtension)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: AssistedKneeExtensionRepresentableView
            init(_ parent: AssistedKneeExtensionRepresentableView) {
                self.parent = parent
            }
        }
    }
}

