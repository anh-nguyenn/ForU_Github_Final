import SwiftUI

struct PosteriorCapsuleStretchView: View {
    @StateObject private var posteriorCapsuleStretchModel: PosteriorCapsuleStretchModel = PosteriorCapsuleStretchModel.shared
    @State private var isCustomCameraViewPresented = true
    @State private var repetitions = PosteriorCapsuleStretchModel.repetitions
    
    @Environment(\.presentationMode) var presentationMode

    let posteriorCapsuleStretchViewController = PosteriorCapsuleStretchViewController()
    
    var body: some View {
        ZStack {
            PosteriorCapsuleStretchRepresentableView(posteriorCapsuleStretchViewController: posteriorCapsuleStretchViewController) { result in
                didDismiss()
            }
            VStack {
                HeaderView(move: posteriorCapsuleStretchModel)
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
                            PosteriorCapsuleStretchModel.repetitions = Int(repetitions)
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
        posteriorCapsuleStretchModel.resetStateMachine()
    }
    
    private var content: some View {
        let state = posteriorCapsuleStretchModel.currentState
        switch state {
        case state as PosteriorCapsuleStretchModel.InitialState: return AnyView(InitialView())
        case state as PosteriorCapsuleStretchModel.CalibrationState: return AnyView(CalibrationView())
        case state as PosteriorCapsuleStretchModel.StartState: return AnyView(StartView())
        case state as PosteriorCapsuleStretchModel.InPositionState: return AnyView(InPositionView())
        case state as PosteriorCapsuleStretchModel.RepetitionState: return AnyView(ProgressView())
        case state as PosteriorCapsuleStretchModel.RepetitionInitialState: return AnyView(RepetitionInitialView())
        case state as PosteriorCapsuleStretchModel.RepetitionInProgressState: return AnyView(RepetitionView())
        case state as PosteriorCapsuleStretchModel.RepetitionCompletedState: return AnyView(RepetitionCompletedView())
        case state as PosteriorCapsuleStretchModel.ExerciseEndState: return AnyView(EndView())
        default: return AnyView(DefaultView())
        }
    }

    func InitialView() -> some View {
        let body: some View = Group {
            if posteriorCapsuleStretchModel.getShared().instructed {
                BottomInstructionsView(text: "Starting stretch...",
                                       move: posteriorCapsuleStretchModel,
                                       remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                       remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
                )
            } else {
                PreMoveInstructonView(move: posteriorCapsuleStretchModel)
            }
        }
        return body
    }
    
    func CalibrationView() -> some View {
        let text: String = "Face the camera with your arms and hips visible."
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: posteriorCapsuleStretchModel,
                                   remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                   remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
            )
        }
        return body
    }
    
    func StartView() -> some View {
        let text: String = "Lift your affected arm across your body and place your other arm at your affected forearm"
        let body: some View = VStack {
            BottomInstructionsView(text: text,
                                   move: posteriorCapsuleStretchModel,
                                   remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                   remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
            )
        }
        return body
    }
    
    func InPositionView() -> some View {
        let body: some View = Group {
            BottomCountDownView(text: "Get ready!",
                                move: posteriorCapsuleStretchModel,
                                remainingDuration: posteriorCapsuleStretchModel.startTimeLeft,
                                remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionInitialView() -> some View {
        let bodyText: String = "Use your unaffected arm to gently pull your affected arm across your body"

        let body: some View = Group {
            BottomInstructionsView(text: bodyText,
                                   move: posteriorCapsuleStretchModel,
                                   remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                   remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionView() -> some View {
        var text: String
        
        if posteriorCapsuleStretchModel.repetitionIsGood {
            text = "Good job, keep going!"
        } else {
            text = "Don't give up!"
        }
        
        let body: some View = Group {
            BottomCountDownView(text: text,
                                move: posteriorCapsuleStretchModel,
                                remainingDuration: posteriorCapsuleStretchModel.repetitionDurationLeft,
                                remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
            )
        }
        return body
    }
    
    func RepetitionCompletedView() -> some View {
        let body: some View = Group {
            BottomInstructionsView(text: TextToSpeech.goodWithRelax,
                                   move: posteriorCapsuleStretchModel,
                                   remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                   remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
            )
                .onAppear {
                    let repNum: Int = Int(PosteriorCapsuleStretchModel.repetitions - posteriorCapsuleStretchModel.remainingRepetitions)
                    if posteriorCapsuleStretchModel.side == .left || (posteriorCapsuleStretchModel.currentSide == .left && posteriorCapsuleStretchModel.side == .both) {
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
                        Text(String(Int(posteriorCapsuleStretchModel.transitionTimer)))
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
                BottomInstructionsView(text: posteriorCapsuleStretchModel.currentState!.description,
                                       move: posteriorCapsuleStretchModel,
                                       remainingSets: posteriorCapsuleStretchModel.remainingSets,
                                       remainingRepetitions: posteriorCapsuleStretchModel.remainingRepetitions
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
                            Text(String(posteriorCapsuleStretchModel.remainingRepetitions))
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Image("VerticalDivider")
                        Spacer()
                        VStack (alignment: .center){
                            Text("Sets Left")
                                .font(.system(size: 16))
                            Text(String(posteriorCapsuleStretchModel.remainingSets))
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
    
    struct PosteriorCapsuleStretchRepresentableView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        let posteriorCapsuleStretchViewController: PosteriorCapsuleStretchViewController
        let posteriorCapsuleStretchModel: PosteriorCapsuleStretchModel = PosteriorCapsuleStretchModel.shared
        let finished: (Result<Bool, Error>) -> ()
        
        func makeUIViewController(context: Context) -> UIViewController {
            posteriorCapsuleStretchViewController.start() { err in
                if let err = err {
                    finished((.failure(err)))
                    return
                }
            }
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(posteriorCapsuleStretchViewController.previewLayer)
            posteriorCapsuleStretchViewController.previewLayer.frame = viewController.view.bounds
            posteriorCapsuleStretchModel.enter(PosteriorCapsuleStretchModel.InitialState.self)
            AudioManager.speakText(text: TextToSpeech.welcomeMessagePosteriorCapsuleStretch)
            return viewController
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {   }

        class Coordinator: NSObject {
            let parent: PosteriorCapsuleStretchRepresentableView
            init(_ parent: PosteriorCapsuleStretchRepresentableView) {
                self.parent = parent
            }
        }
    }
}
