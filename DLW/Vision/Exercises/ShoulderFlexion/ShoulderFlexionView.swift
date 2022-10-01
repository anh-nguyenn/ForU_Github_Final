import SwiftUI

struct ShoulderFlexionView: View {
    @StateObject private var shoulderFlexionModel: ShoulderFlexionModel = ShoulderFlexionModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = ShoulderFlexionModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let shoulderFlexionViewController = ShoulderFlexionViewController()
    
    var body: some View {
        ZStack {
            ShoulderFlexionRepresentableView(shoulderFlexionViewController: shoulderFlexionViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: shoulderFlexionModel)
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
                            ShoulderFlexionModel.repetitions = Int(repetitions)
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
        shoulderFlexionModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = shoulderFlexionModel.currentState
        
        switch state {
        case state as ShoulderFlexionModel.InitialState: return AnyView(InitialView())
        case state as ShoulderFlexionModel.CalibrationState: return AnyView(CalibrationView())
        case state as ShoulderFlexionModel.StartState: return AnyView(StartView())
        case state as ShoulderFlexionModel.InPositionState: return AnyView(InPositionView())
        case state as ShoulderFlexionModel.RepetitionState: return AnyView(ProgressView())
        case state as ShoulderFlexionModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as ShoulderFlexionModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as ShoulderFlexionModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as ShoulderFlexionModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if shoulderFlexionModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: shoulderFlexionModel,
                                       remainingSets: shoulderFlexionModel.remainingSets,
                                       remainingRepetitions: shoulderFlexionModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: shoulderFlexionModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text = "Adjust your position such that your affected shoulder and arm can be seen."
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: shoulderFlexionModel,
                                   remainingSets: shoulderFlexionModel.remainingSets,
                                   remainingRepetitions: shoulderFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String
        
        switch(shoulderFlexionModel.side) {
        case .left:
            text = "While facing 90 degrees to the right, step on a resistance band with your left foot and hold the other end of the band in your arm"
            break
        case .right:
            text = "While facing 90 degrees to the left, step on a resistance band with your right foot and hold the other end of the band in your arm"
            break
        case .both:
            if shoulderFlexionModel.currentSide == .left {
                if shoulderFlexionModel.firstLeftRepetition {
                    text = "Now face the other side, step on a resistance band with your left foot and hold the other end of the band in your arm"
                }
                else {
                    text = "While facing 90 degrees to the right, step on a resistance band with your left foot and hold the other end of the band in your arm"
                }
            } else {
                text = "While facing 90 degrees to the left, step on a resistance band with your right foot and hold the other end of the band in your arm"
            }
            break
        default:
            text = "While facing 90 degrees to the left, step on a resistance band with your right foot and hold the other end of the band in your arm"
        }
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: shoulderFlexionModel,
                                   remainingSets: shoulderFlexionModel.remainingSets,
                                   remainingRepetitions: shoulderFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: shoulderFlexionModel,
                                remainingDuration: shoulderFlexionModel.startTimeLeft,
                                remainingSets: shoulderFlexionModel.remainingSets,
                                remainingRepetitions: shoulderFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let text: String = "While keeping your arm straight, slowly raise the arm forward."
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: shoulderFlexionModel,
                                   remainingSets: shoulderFlexionModel.remainingSets,
                                   remainingRepetitions: shoulderFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if shoulderFlexionModel.repetitionIsGood {
            if shoulderFlexionModel.currentAngleFrames < 40 {
                text = "Good job, keep going!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: shoulderFlexionModel,
                                remainingDuration: shoulderFlexionModel.repetitionDurationLeft,
                                remainingSets: shoulderFlexionModel.remainingSets,
                                remainingRepetitions: shoulderFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String = "Good job! Now slowly bring your arm back down with control."

        if shoulderFlexionModel.setCompleted {
            text = "Set \(ShoulderFlexionModel.sets - shoulderFlexionModel.remainingSets + 1) Completed!"
        } else {
            if shoulderFlexionModel.isGiveUp {
                text = TextToSpeech.doNotGiveUp
            }
        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: shoulderFlexionModel,
                                   remainingSets: shoulderFlexionModel.remainingSets,
                                   remainingRepetitions: shoulderFlexionModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = ShoulderFlexionModel.repetitions - shoulderFlexionModel.remainingRepetitions
                    if shoulderFlexionModel.side == .left || (shoulderFlexionModel.side == .both && shoulderFlexionModel.currentSide == .left) {
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
                        Text(String(Int(shoulderFlexionModel.transitionTimer)))
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
                BottomInstructionsView(text: shoulderFlexionModel.currentState!.description,
                                       move: shoulderFlexionModel,
                                       remainingSets: shoulderFlexionModel.remainingSets,
                                       remainingRepetitions: shoulderFlexionModel.remainingRepetitions
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
                                Text(String(shoulderFlexionModel.remainingRepetitions))
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            Image("VerticalDivider")
                            Spacer()
                            VStack (alignment: .center){
                                Text("Sets Left")
                                    .font(.system(size: 16))
                                Text(String(shoulderFlexionModel.remainingSets))
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
    
    struct ShoulderFlexionRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let shoulderFlexionViewController: ShoulderFlexionViewController
        let shoulderFlexionModel: ShoulderFlexionModel = ShoulderFlexionModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            shoulderFlexionViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(shoulderFlexionViewController.previewLayer)
            shoulderFlexionViewController.previewLayer.frame = viewController.view.bounds
            shoulderFlexionModel.enter(ShoulderFlexionModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageShoulderFlexion)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: ShoulderFlexionRepresentableView
            init(_ parent: ShoulderFlexionRepresentableView) {
                self.parent = parent
            }
        }
    }
}
