import SwiftUI

struct BicepsFlexionView: View {
    @StateObject private var bicepsFlexionModel: BicepsFlexionModel = BicepsFlexionModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = BicepsFlexionModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let bicepsFlexionViewController = BicepsFlexionViewController()
    
    var body: some View {
        ZStack {
            BicepsFlexionRepresentableView(bicepsFlexionViewController: bicepsFlexionViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: bicepsFlexionModel)
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
                            BicepsFlexionModel.repetitions = Int(repetitions)
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
        bicepsFlexionModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = bicepsFlexionModel.currentState
        
        switch state {
        case state as BicepsFlexionModel.InitialState: return AnyView(InitialView())
        case state as BicepsFlexionModel.CalibrationState: return AnyView(CalibrationView())
        case state as BicepsFlexionModel.StartState: return AnyView(StartView())
        case state as BicepsFlexionModel.InPositionState: return AnyView(InPositionView())
        case state as BicepsFlexionModel.RepetitionState: return AnyView(ProgressView())
        case state as BicepsFlexionModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as BicepsFlexionModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as BicepsFlexionModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as BicepsFlexionModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if bicepsFlexionModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: bicepsFlexionModel,
                                       remainingSets: bicepsFlexionModel.remainingSets,
                                       remainingRepetitions: bicepsFlexionModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: bicepsFlexionModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String = "Adjust your position such that your affected arm and corresponding leg can be seen."
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: bicepsFlexionModel,
                                   remainingSets: bicepsFlexionModel.remainingSets,
                                   remainingRepetitions: bicepsFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String
        
        switch(bicepsFlexionModel.side) {
        case .left:
            text = "Use your left leg to step on the resistance band and grab the band with your left arm."
            break
        case .right:
            text = "Use your right leg to step on the resistance band and grab the band with your right arm."
            break
        case .both:
            if bicepsFlexionModel.currentSide == .left {
                if bicepsFlexionModel.firstLeftRepetition {
                    text = "Now ensure your left arm is facing the camera and place your left hand's middle and index finger lower down on a wall."
                }
                else {
                    text = "Use your left leg to step on the resistance band and grab the band with your left arm."
                }
            } else {
                text = "Use your right leg to step on the resistance band and grab the band with your right arm."
            }
            break
        default:
            text = "Use your right leg to step on the resistance band and grab the band with your right arm."
        }
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: bicepsFlexionModel,
                                   remainingSets: bicepsFlexionModel.remainingSets,
                                   remainingRepetitions: bicepsFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: bicepsFlexionModel,
                                remainingDuration: bicepsFlexionModel.startTimeLeft,
                                remainingSets: bicepsFlexionModel.remainingSets,
                                remainingRepetitions: bicepsFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let text: String = "Bend your arm upwards slowly around the elbow joint."
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: bicepsFlexionModel,
                                   remainingSets: bicepsFlexionModel.remainingSets,
                                   remainingRepetitions: bicepsFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if bicepsFlexionModel.repetitionIsGood {
            if bicepsFlexionModel.currentAngleFrames < 40 {
                text = "Good job, keep going!"
            } else {
                text = "Hold it!"
            }
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: bicepsFlexionModel,
                                remainingDuration: bicepsFlexionModel.repetitionDurationLeft,
                                remainingSets: bicepsFlexionModel.remainingSets,
                                remainingRepetitions: bicepsFlexionModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        var text: String = "Now lower your arm back down slowly and with control."

        if bicepsFlexionModel.setCompleted {
            text = "Set \(BicepsFlexionModel.sets - bicepsFlexionModel.remainingSets + 1) Completed!"
        } else {
            if bicepsFlexionModel.isGiveUp {
                text = TextToSpeech.doNotGiveUp
            }
        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: bicepsFlexionModel,
                                   remainingSets: bicepsFlexionModel.remainingSets,
                                   remainingRepetitions: bicepsFlexionModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = BicepsFlexionModel.repetitions - bicepsFlexionModel.remainingRepetitions
                    if bicepsFlexionModel.side == .left || (bicepsFlexionModel.side == .both && bicepsFlexionModel.currentSide == .left) {
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
                        Text(String(Int(bicepsFlexionModel.transitionTimer)))
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
                BottomInstructionsView(text: bicepsFlexionModel.currentState!.description,
                                       move: bicepsFlexionModel,
                                       remainingSets: bicepsFlexionModel.remainingSets,
                                       remainingRepetitions: bicepsFlexionModel.remainingRepetitions
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
                            Text(String(bicepsFlexionModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(bicepsFlexionModel.remainingSets))
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
    
    struct BicepsFlexionRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let bicepsFlexionViewController: BicepsFlexionViewController
        let bicepsFlexionModel: BicepsFlexionModel = BicepsFlexionModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            bicepsFlexionViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(bicepsFlexionViewController.previewLayer)
            bicepsFlexionViewController.previewLayer.frame = viewController.view.bounds
            bicepsFlexionModel.enter(BicepsFlexionModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeBicepFlexionWithResistanceBand)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: BicepsFlexionRepresentableView
            init(_ parent: BicepsFlexionRepresentableView) {
                self.parent = parent
            }
        }
    }
}
