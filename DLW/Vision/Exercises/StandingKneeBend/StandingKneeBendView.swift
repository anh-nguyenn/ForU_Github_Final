import SwiftUI

struct StandingKneeBendView: View {
    @StateObject private var standingKneeBendModel: StandingKneeBendModel = StandingKneeBendModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = StandingKneeBendModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let standingKneeBendViewController = StandingKneeBendViewController()
    
    var body: some View {
        ZStack {
            StandingKneeBendRepresentableView(standingKneeBendViewController: standingKneeBendViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: standingKneeBendModel)
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
                            StandingKneeBendModel.repetitions = Int(repetitions)
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
        standingKneeBendModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = standingKneeBendModel.currentState
        switch state {
        case state as StandingKneeBendModel.InitialState: return AnyView(InitialView())
        case state as StandingKneeBendModel.CalibrationState: return AnyView(CalibrationView())
        case state as StandingKneeBendModel.StartState: return AnyView(StartView())
        case state as StandingKneeBendModel.InPositionState: return AnyView(InPositionView())
        case state as StandingKneeBendModel.RepetitionState: return AnyView(ProgressView())
        case state as StandingKneeBendModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as StandingKneeBendModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as StandingKneeBendModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as StandingKneeBendModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if standingKneeBendModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: standingKneeBendModel,
                                       remainingSets: standingKneeBendModel.remainingSets,
                                       remainingRepetitions: standingKneeBendModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: standingKneeBendModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String = "Ensure that your entire leg can be seen in the frame."
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: standingKneeBendModel,
                                   remainingSets: standingKneeBendModel.remainingSets,
                                   remainingRepetitions: standingKneeBendModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String
        
        switch(standingKneeBendModel.side) {
        case .left:
            text = "Turn 90 degrees such that your left leg is facing the camera and hold onto a support infront of you."
            break
        case .right:
            text = "Turn 90 degrees such that your right leg is facing the camera and hold onto a support infront of you."
            break
        case .both:
            if standingKneeBendModel.currentSide == .left {
                if standingKneeBendModel.firstLeftRepetition {
                    text = "Now turn to the other side, ensuring that your left leg is facing the camera."
                } else {
                    text = "Turn 90 degrees such that your left leg is facing the camera and hold onto a support infront of you."
                }
            } else {
                text = "Turn 90 degrees such that your right leg is facing the camera and hold onto a support infront of you."
            }
            break
        default:
            text = "Turn 90 degrees such that your right leg is facing the camera and hold onto a support infront of you."
        }
        
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: standingKneeBendModel,
                                   remainingSets: standingKneeBendModel.remainingSets,
                                   remainingRepetitions: standingKneeBendModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: standingKneeBendModel,
                                remainingDuration: standingKneeBendModel.startTimeLeft,
                                remainingSets: standingKneeBendModel.remainingSets,
                                remainingRepetitions: standingKneeBendModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let text: String
        if standingKneeBendModel.side == .left || (standingKneeBendModel.currentSide == .left && standingKneeBendModel.side == .both) {
            text = "Bend your left knee to about 90 degrees."
        } else {
            text = "Bend your right knee to about 90 degrees."
        }
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: standingKneeBendModel,
                                   remainingSets: standingKneeBendModel.remainingSets,
                                   remainingRepetitions: standingKneeBendModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var color: Color
        var text: String
        
        if standingKneeBendModel.repetitionIsGood {
            color = .green
            text = "Hold this position!"
        } else {
            color = .red
            text = "Don't give up! Bring your leg back up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: standingKneeBendModel,
                                remainingDuration: Float(standingKneeBendModel.repetitionDurationLeft),
                                remainingSets: standingKneeBendModel.remainingSets,
                                remainingRepetitions: standingKneeBendModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        let text: String
        
        if standingKneeBendModel.goodFrames >= standingKneeBendModel.badFrames {
            text = "Good job! Now relax."
        } else {
            text = "Do better next time! Now relax."
        }
        
        let body: some View = Group {
            BottomInstructionsView(text: text,
                                   move: standingKneeBendModel,
                                   remainingSets: standingKneeBendModel.remainingSets,
                                   remainingRepetitions: standingKneeBendModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = Int(StandingKneeBendModel.repetitions - standingKneeBendModel.remainingRepetitions)
                    if standingKneeBendModel.side == .left || (standingKneeBendModel.currentSide == .left && standingKneeBendModel.side == .both) {
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
                        Text(String(Int(standingKneeBendModel.transitionTimer)))
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
                BottomInstructionsView(text: standingKneeBendModel.currentState!.description,
                                       move: standingKneeBendModel,
                                       remainingSets: standingKneeBendModel.remainingSets,
                                       remainingRepetitions: standingKneeBendModel.remainingRepetitions
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
                            Text(String(standingKneeBendModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(standingKneeBendModel.remainingSets))
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
    
    struct StandingKneeBendRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let standingKneeBendViewController: StandingKneeBendViewController
        let standingKneeBendModel: StandingKneeBendModel = StandingKneeBendModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            standingKneeBendViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(standingKneeBendViewController.previewLayer)
            standingKneeBendViewController.previewLayer.frame = viewController.view.bounds
            standingKneeBendModel.enter(StandingKneeBendModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessageStandingKneeBend)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: StandingKneeBendRepresentableView
            init(_ parent: StandingKneeBendRepresentableView) {
                self.parent = parent
            }
        }
    }
}
