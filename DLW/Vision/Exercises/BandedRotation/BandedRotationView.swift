import SwiftUI

struct BandedRotationView: View {
    @StateObject private var bandedRotationModel: BandedRotationModel = BandedRotationModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = BandedRotationModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let bandedRotationViewController = BandedRotationViewController()
    
    var body: some View {
        ZStack {
            BandedRotationRepresentableView(bandedRotationViewController: bandedRotationViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: bandedRotationModel)
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
                            BandedRotationModel.repetitions = Int(repetitions)
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
        bandedRotationModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = bandedRotationModel.currentState
        
        switch state {
        case state as BandedRotationModel.InitialState: return AnyView(InitialView())
        case state as BandedRotationModel.CalibrationState: return AnyView(CalibrationView())
        case state as BandedRotationModel.StartState: return AnyView(StartView())
        case state as BandedRotationModel.InPositionState: return AnyView(InPositionView())
        case state as BandedRotationModel.RepetitionState: return AnyView(ProgressView())
        case state as BandedRotationModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as BandedRotationModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as BandedRotationModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as BandedRotationModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if bandedRotationModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: bandedRotationModel,
                                       remainingSets: bandedRotationModel.remainingSets,
                                       remainingRepetitions: bandedRotationModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: bandedRotationModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String = "Face the camera with your shoulders and arms visible."
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: bandedRotationModel,
                                   remainingSets: bandedRotationModel.remainingSets,
                                   remainingRepetitions: bandedRotationModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String = "While seated, bend your elbows and wrap a resistance band around both hands."
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: bandedRotationModel,
                                   remainingSets: bandedRotationModel.remainingSets,
                                   remainingRepetitions: bandedRotationModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: bandedRotationModel,
                                remainingDuration: bandedRotationModel.startTimeLeft,
                                remainingSets: bandedRotationModel.remainingSets,
                                remainingRepetitions: bandedRotationModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let text: String =  "With both elbows in contact with your body, rotate both your arms outwards."
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: bandedRotationModel,
                                   remainingSets: bandedRotationModel.remainingSets,
                                   remainingRepetitions: bandedRotationModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if bandedRotationModel.repetitionIsGood {
            if bandedRotationModel.currentAngleFrames < 40 {
                text = "Rotate out as much as possible!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: bandedRotationModel,
                                remainingDuration: bandedRotationModel.repetitionDurationLeft,
                                remainingSets: bandedRotationModel.remainingSets,
                                remainingRepetitions: bandedRotationModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String = "Good job! Now bring your arms back to the middle slowly and with control."

        if bandedRotationModel.setCompleted {
            text = "Set \(BandedRotationModel.sets - bandedRotationModel.remainingSets + 1) Completed!"
        } else {
            if bandedRotationModel.isGiveUp {
                text = TextToSpeech.doNotGiveUp
            }
        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: bandedRotationModel,
                                   remainingSets: bandedRotationModel.remainingSets,
                                   remainingRepetitions: bandedRotationModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = Int(BandedRotationModel.repetitions - bandedRotationModel.remainingRepetitions)
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
                        Text(String(Int(bandedRotationModel.transitionTimer)))
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
                BottomInstructionsView(text: bandedRotationModel.currentState!.description,
                                       move: bandedRotationModel,
                                       remainingSets: bandedRotationModel.remainingSets,
                                       remainingRepetitions: bandedRotationModel.remainingRepetitions
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
                            Text(String(bandedRotationModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(bandedRotationModel.remainingSets))
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
    
    struct BandedRotationRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let bandedRotationViewController: BandedRotationViewController
        let bandedRotationModel: BandedRotationModel = BandedRotationModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            bandedRotationViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(bandedRotationViewController.previewLayer)
            bandedRotationViewController.previewLayer.frame = viewController.view.bounds
            bandedRotationModel.enter(BandedRotationModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageBandedRotation)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: BandedRotationRepresentableView
            init(_ parent: BandedRotationRepresentableView) {
                self.parent = parent
            }
        }
    }
}
