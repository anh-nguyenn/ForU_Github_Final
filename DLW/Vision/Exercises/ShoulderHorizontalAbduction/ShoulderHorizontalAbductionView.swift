import SwiftUI

struct ShoulderHorizontalAbductionView: View {
    @StateObject private var shoulderHorizontalAbductionModel: ShoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = ShoulderHorizontalAbductionModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let shoulderHorizontalAbductionViewController = ShoulderHorizontalAbductionViewController()
    
    var body: some View {
        ZStack {
            ShoulderHorizontalAbductionRepresentableView(shoulderHorizontalAbductionViewController: shoulderHorizontalAbductionViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: shoulderHorizontalAbductionModel)
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
                            ShoulderHorizontalAbductionModel.repetitions = Int(repetitions)
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
        shoulderHorizontalAbductionModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = shoulderHorizontalAbductionModel.currentState
        switch state {
        case state as ShoulderHorizontalAbductionModel.InitialState: return AnyView(InitialView())
        case state as ShoulderHorizontalAbductionModel.CalibrationState: return AnyView(CalibrationView())
        case state as ShoulderHorizontalAbductionModel.StartState: return AnyView(StartView())
        case state as ShoulderHorizontalAbductionModel.InPositionState: return AnyView(InPositionView())
        case state as ShoulderHorizontalAbductionModel.RepetitionState: return AnyView(ProgressView())
        case state as ShoulderHorizontalAbductionModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as ShoulderHorizontalAbductionModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as ShoulderHorizontalAbductionModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as ShoulderHorizontalAbductionModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if shoulderHorizontalAbductionModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: shoulderHorizontalAbductionModel,
                                       remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                       remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: shoulderHorizontalAbductionModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String = "Face the camera with your shoulders and arms visible at all times and wrap a resistance band around both hands."
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: shoulderHorizontalAbductionModel,
                                   remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String = "Keep your arms straight towards the camera."

        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: shoulderHorizontalAbductionModel,
                                   remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: shoulderHorizontalAbductionModel,
                                remainingDuration: shoulderHorizontalAbductionModel.startTimeLeft,
                                remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let bodyText: String = "Slowly rotate both your arms outwards."
        
        let body: some View = Group {
            BottomInstructionsView(text: bodyText,
                                   move: shoulderHorizontalAbductionModel,
                                   remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if shoulderHorizontalAbductionModel.repetitionIsGood {
            if shoulderHorizontalAbductionModel.currentAngleFrames < 40 {
                text = "Good job, keep going!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: shoulderHorizontalAbductionModel,
                                remainingDuration: shoulderHorizontalAbductionModel.repetitionDurationLeft,
                                remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String
        
        if shoulderHorizontalAbductionModel.setCompleted {
            text = "Set \(ShoulderHorizontalAbductionModel.sets - shoulderHorizontalAbductionModel.remainingSets + 1) Completed!"
        } else {
            text = "Good job! Now bring your arm back to the middle slowly and with control."
            if shoulderHorizontalAbductionModel.isGiveUp {
                text = TextToSpeech.doNotGiveUp
            }

        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: shoulderHorizontalAbductionModel,
                                   remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                   remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = ShoulderHorizontalAbductionModel.repetitions - shoulderHorizontalAbductionModel.remainingRepetitions
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
                        Text(String(Int(shoulderHorizontalAbductionModel.transitionTimer)))
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
                BottomInstructionsView(text: shoulderHorizontalAbductionModel.currentState!.description,
                                       move: shoulderHorizontalAbductionModel,
                                       remainingSets: shoulderHorizontalAbductionModel.remainingSets,
                                       remainingRepetitions: shoulderHorizontalAbductionModel.remainingRepetitions
                )
            }
        }
        return body
    }
    
    func ProgressView() -> some View {
        let body: some View = VStack {
            Spacer()
            VStack {
                VStack (alignment: .center) {
                    HStack {
                        Spacer()
                        VStack (alignment: .center){
                            Text("Reps Left")
                                .font(.system(size: 16))
                            Text(String(shoulderHorizontalAbductionModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(shoulderHorizontalAbductionModel.remainingSets))
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
    
    struct ShoulderHorizontalAbductionRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let shoulderHorizontalAbductionViewController: ShoulderHorizontalAbductionViewController
        let shoulderHorizontalAbductionModel: ShoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            shoulderHorizontalAbductionViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(shoulderHorizontalAbductionViewController.previewLayer)
            shoulderHorizontalAbductionViewController.previewLayer.frame = viewController.view.bounds
            shoulderHorizontalAbductionModel.enter(ShoulderHorizontalAbductionModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageShoulderHorizontalAbductionWithResistanceBand)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: ShoulderHorizontalAbductionRepresentableView
            init(_ parent: ShoulderHorizontalAbductionRepresentableView) {
                self.parent = parent
            }
        }
    }
}
