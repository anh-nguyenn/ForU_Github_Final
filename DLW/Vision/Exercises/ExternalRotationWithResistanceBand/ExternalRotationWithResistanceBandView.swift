import SwiftUI

struct ExternalRotationWithResistanceBandView: View {
    @StateObject private var externalRotationWithResistanceBandModel: ExternalRotationWithResistanceBandModel = ExternalRotationWithResistanceBandModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = ExternalRotationWithResistanceBandModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let externalRotationWithResistanceBandViewController = ExternalRotationWithResistanceBandViewController()
    
    var body: some View {
        ZStack {
            ExternalRotationWithResistanceBandRepresentableView(externalRotationWithResistanceBandViewController: externalRotationWithResistanceBandViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: externalRotationWithResistanceBandModel)
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
                            ExternalRotationWithResistanceBandModel.repetitions = Int(repetitions)
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
        externalRotationWithResistanceBandModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = externalRotationWithResistanceBandModel.currentState
        
        switch state {
        case state as ExternalRotationWithResistanceBandModel.InitialState: return AnyView(InitialView())
        case state as ExternalRotationWithResistanceBandModel.CalibrationState: return AnyView(CalibrationView())
        case state as ExternalRotationWithResistanceBandModel.StartState: return AnyView(StartView())
        case state as ExternalRotationWithResistanceBandModel.InPositionState: return AnyView(InPositionView())
        case state as ExternalRotationWithResistanceBandModel.RepetitionState: return AnyView(ProgressView())
        case state as ExternalRotationWithResistanceBandModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as ExternalRotationWithResistanceBandModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as ExternalRotationWithResistanceBandModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as ExternalRotationWithResistanceBandModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if externalRotationWithResistanceBandModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: externalRotationWithResistanceBandModel,
                                       remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                       remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: externalRotationWithResistanceBandModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String = "Tie resistance band higher up onto secure structure, place a towel between elbow and body, and adjust your position such that your shoulders and arms can be seen."
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: externalRotationWithResistanceBandModel,
                                   remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                   remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String
        
        switch(externalRotationWithResistanceBandModel.side) {
        case .left:
            text = "Hold the other end of the band in your left arm, and keep your elbow in contact with your body at all times."
            break
        case .right:
            text = "Hold the other end of the band in your right arm, and keep your elbow in contact with your body at all times."
            break
        case .both:
            if externalRotationWithResistanceBandModel.currentSide == .left {
                if externalRotationWithResistanceBandModel.firstLeftRepetition {
                    text = "Now hold the other end of the band in your left arm, and keep your elbow in contact with your body at all times."
                }
                else {
                    text = "Hold the other end of the band in your left arm, and keep your elbow in contact with your body at all times."
                }
            } else {
                text = "Hold the other end of the band in your right arm, and keep your elbow in contact with your body at all times."
            }
            break
        default:
            text = "Hold the other end of the band in your right arm, and keep your elbow in contact with your body at all times."
        }
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: externalRotationWithResistanceBandModel,
                                   remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                   remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: externalRotationWithResistanceBandModel,
                                remainingDuration: externalRotationWithResistanceBandModel.startTimeLeft,
                                remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let text: String = "Slowly rotate your arm outwards."
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: externalRotationWithResistanceBandModel,
                                   remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                   remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if externalRotationWithResistanceBandModel.repetitionIsGood {
            if externalRotationWithResistanceBandModel.currentAngleFrames < 40 {
                text = "Good job, keep going!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: externalRotationWithResistanceBandModel,
                                remainingDuration: externalRotationWithResistanceBandModel.repetitionDurationLeft,
                                remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String = "Good job! Now slowly bring your arm back with control."

        if externalRotationWithResistanceBandModel.setCompleted {
            text = "Set \(ExternalRotationWithResistanceBandModel.sets - externalRotationWithResistanceBandModel.remainingSets + 1) Completed!"
        } else {
            if externalRotationWithResistanceBandModel.isGiveUp {
                text = TextToSpeech.doNotGiveUp
            }
        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: externalRotationWithResistanceBandModel,
                                   remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                   remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = ExternalRotationWithResistanceBandModel.repetitions - externalRotationWithResistanceBandModel.remainingRepetitions
                    if externalRotationWithResistanceBandModel.side == .left || (externalRotationWithResistanceBandModel.side == .both && externalRotationWithResistanceBandModel.currentSide == .left) {
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
                        Text(String(Int(externalRotationWithResistanceBandModel.transitionTimer)))
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
                BottomInstructionsView(text: externalRotationWithResistanceBandModel.currentState!.description,
                                       move: externalRotationWithResistanceBandModel,
                                       remainingSets: externalRotationWithResistanceBandModel.remainingSets,
                                       remainingRepetitions: externalRotationWithResistanceBandModel.remainingRepetitions
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
                            Text(String(externalRotationWithResistanceBandModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(externalRotationWithResistanceBandModel.remainingSets))
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
    
    struct ExternalRotationWithResistanceBandRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let externalRotationWithResistanceBandViewController: ExternalRotationWithResistanceBandViewController
        let externalRotationWithResistanceBandModel: ExternalRotationWithResistanceBandModel = ExternalRotationWithResistanceBandModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            externalRotationWithResistanceBandViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(externalRotationWithResistanceBandViewController.previewLayer)
            externalRotationWithResistanceBandViewController.previewLayer.frame = viewController.view.bounds
            externalRotationWithResistanceBandModel.enter(ExternalRotationWithResistanceBandModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageExternalRotationWithResistanceBand)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: ExternalRotationWithResistanceBandRepresentableView
            init(_ parent: ExternalRotationWithResistanceBandRepresentableView) {
                self.parent = parent
            }
        }
    }
}
