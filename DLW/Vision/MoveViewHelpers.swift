//
//  MoveViewHelpers.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import SwiftUI

/**
 Creates a dictionary with the data needed for the summary page.
 
 - Parameters:
    - move: The move that data is needed from.
 
 - Returns: A dictionary containing the exercise's side, total reps, total sets, completed sets, and completed reps.
 */
func generateMoveData(move: Move) -> [String : Int]{
    let side: Int
    var totalSets: Int = move.totalSets
    var totalReps: Int = move.totalRepetitions
    switch(move.getShared().side) {
    case .left:
        side = 0
        break
    case .right:
        side = 1
        break
    case .both:
        side = 2
        totalSets = move.totalSets * 2
        totalReps = move.totalRepetitions * 2
        break
    default:
        side = 3
    }
    
    let data = ["side": side,
                "totalReps": totalReps,
                "totalSets": totalSets,
                "completedSets": move.completedSets,
                "completedReps": move.completedReps]
    return data
}

/**
 Creates a view with the VAS scale images depending on the percentage of repetitions completed of a session.
 
 - Returns: A view with the VAS scale image
 */
func vasScaleImage() -> some View {
    let percentageCompleted : Float = Float(Move.finishedReps / Move.totalReps)
    let category : Int = percentageCompleted > 0.8 ? 1 : percentageCompleted > 0.6 ? 2 : percentageCompleted > 0.4 ? 3 : percentageCompleted > 0.2 ? 4 : 5
    var image : Image
    var feedback : String = ""
    switch(category) {
    case 1:
        image = Image("VAS-Laugh")
        feedback = "Great job! You have over 80% completed repetitions!"
    case 2:
        image = Image("VAS-Smile")
        feedback = "Good job! You have over 60% completed repetitions!"
    case 3:
        image = Image("VAS-Meh")
        feedback = "You have over 40% completed repetitions!"
    case 4:
        image = Image("VAS-Frown")
        feedback = "You have less than 40% completed repetitions, try harder next time!"
    case 5:
        image = Image("VAS-OpenFrown")
        feedback = "You have less than 20% completed repetitions, try harder next time!"
    default:
        image = Image("VAS-Meh")
    }
    
    let body: some View = VStack {
        image
            .resizable()
            .frame(width: 100, height: 100)
            .padding(.horizontal)
        Text(feedback)
            .font(.system(size: 16))
            .padding(.horizontal)
    }
        .padding(.horizontal)
    return body
}

/**
 Adds an instructional overlay at the top of the screen over a `MoveView`

 - Parameters:
    - text: Instruction to be displayed
    - backgroundColor: Color of the Background
 
 - Returns: A instructional overlay at the top of the screen
*/

func TopInstructionsView(text: String, backgroundColor: Color) -> some View {
    let body: some View = ZStack {
        VStack (alignment: .center) {
            Text(text)
                .padding([.bottom, .leading, .trailing])
                .foregroundColor(.black)
                .font(.largeTitle)
                .background(backgroundColor)
                .cornerRadius(10, corners: .allCorners)
            Spacer()
        }
    }
    return body
}

func BottomInstructionsView(text: String, move: Move, remainingSets:Int, remainingRepetitions:Int) -> some View {
    let body: some View =
    VStack{
        Spacer()
        VStack {
            VStack (alignment: .center) {
                HStack {
                    Spacer()
                    Text(text)
                        .font(.system(size: 20))
                        .fontWeight(.medium)
                    Spacer()
                }
                HStack {
                    Spacer()
                    VStack (alignment: .center){
                        Text("Reps Left")
                            .font(.system(size: 16))
                        Text(String(remainingRepetitions))
                            .font(.system(size: 22))
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    Image("VerticalDivider")
                    Spacer()
                    VStack (alignment: .center){
                        Text("Sets Left")
                            .font(.system(size: 16))
                        Text(String(remainingSets))
                            .font(.system(size: 22))
                            .fontWeight(.semibold)
                    }
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
    .overlay(alignment: .topTrailing) {
        GifView(image: move.smallImage)
            .frame(minWidth: 0, maxWidth: 100, minHeight: 0, maxHeight: 100)
            .cornerRadius(5)
    }
    return body
}

func BottomCountDownView(text: String, move: Move, remainingDuration:Float, remainingSets:Int, remainingRepetitions:Int) -> some View {
    let body: some View =
    VStack () {
        Spacer()
        VStack {
            VStack (alignment: .center) {
                HStack {
                    Spacer()
                    Text(text)
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text(String(Int(remainingDuration)))
                        .font(.system(size: 22))
                        .fontWeight(.semibold)
                    Spacer()
                }
                HStack {
                    Spacer()
                    VStack (alignment: .center){
                        Text("Reps Left")
                            .font(.system(size: 16))
                        Text(String(remainingRepetitions))
                            .font(.system(size: 22))
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Image("VerticalDivider")
                    Spacer()
                    VStack (alignment: .center){
                        Text("Sets Left")
                            .font(.system(size: 16))
                        Text(String(remainingSets))
                            .font(.system(size: 22))
                            .fontWeight(.medium)
                    }
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
    .overlay(alignment: .topTrailing) {
        GifView(image: move.smallImage)
            .frame(minWidth: 0, maxWidth: 100, minHeight: 0, maxHeight: 100)
            .cornerRadius(5)
    }
        
    return body
}

/**
 Adds an instructional overlay at the right side of the screen over a `MoveView`. Used for exercises that are conducted in landscape orientation.

 - Parameters:
    - text: Instruction to be displayed
    - backgroundColor: Color of the Background
 
 - Returns: A instructional overlay at the top of the screen
*/
func LandscapeTopInstructionView(text: String, backgroundColor: Color) -> some View {
    var body: some View {
        GeometryReader { gp in
          VStack {
            Text(text)
                  .frame(width: gp.size.height*0.8, height: gp.size.width*0.8)
              .font(.largeTitle)
              .background(backgroundColor)
              .rotationEffect(Angle(degrees: 90))
              .padding(.leading, 100)
              .padding(.top, 50)
          }
          .frame(width: gp.size.width, height: gp.size.height)
        }
    }
    return body
}

/**
 Adds an overlay containing the exercise GIF and a countdown before the exercise starts over a `MoveView`
 
 - Parameters:
    - move: The move which the view is created for
 
 - Returns: An overlay which covers the whole screen containing the GIF and coundown
 */
func PreMoveInstructonView(move: Move) -> some View {
    let body: some View = ZStack {
        Color.white.edgesIgnoringSafeArea(.all)
        VStack {
            GifView(image: move.image)
                .frame(width: Move.instructionImageDimension, height: Move.instructionImageDimension)
                .padding(.bottom, 125)
            VStack (alignment: .center) {
                Text(move.name)
                    .font(.system(size:24))
                    .fontWeight(.bold)
                    .frame(height: 29)
                VStack {
                    Text("Starting in")
                        .font(.system(size:16))
                        .fontWeight(.medium)
                    Text( "00:0" + String(Int(move.getShared().transitionTimer + 1)))
                        .font(.system(size:36))
                        .fontWeight(.bold)
                }
            }.padding()
        }
        .padding(.top, 30)
    }
    .background(.white)
    .ignoresSafeArea()
    return body
}


func HeaderView(move: Move) -> AnyView? {
    if move.getShared().instructed {
        let body: some View = Spacer().frame(height: 100)
        return AnyView(body)
    }
    return nil
}

/**
Adds an instructional countdown overlay at the top of the screen over a `MoveView`

 - Parameters:
    - text: Instruction to be displayed
 */
//func CountdownView(text: String, backgroundColor: Color, remainingDuration: Float) -> some View {
//    let body: some View = ZStack {
//        VStack (alignment: .center) {
//            VStack {
//                Text(text)
//                Text(String(Int(remainingDuration)))
//            }
//            .foregroundColor(.black)
//            .font(.system(size: 16))
//            .background(backgroundColor)
//            .cornerRadius(10, corners: .allCorners)
//        }
//    }
//    return body
//}

/**
 Adds an instructional overlay at the right side of the screen over a `MoveView`. Used for exercises that are conducted in landscape orientation.

 - Parameters:
    - text: Instruction to be displayed
    - backgroundColor: Color of the Background
 
 - Returns: A instructional overlay at the top of the screen
*/
func LandscapeCountdownView(text: String, backgroundColor: Color, remainingDuration: Float) -> some View {
    var body: some View {
        GeometryReader { gp in
            VStack {
                VStack {
                    Text(text)
                    Text(String(Int(remainingDuration)))
                }
                  .frame(width: gp.size.height*0.8, height: gp.size.width*0.6)
                  .font(.largeTitle)
                  .background(backgroundColor)
                  .rotationEffect(Angle(degrees: 90))
                  .padding(.leading, 100)
                  .padding(.top, 50)
          }
          .frame(width: gp.size.width, height: gp.size.height)
        }
    }
    return body
}

/// Resizes gif images of each exercise.
/// - Parameters:
///     - gif: UIImage to be resized
///  - Returns:
///     - UIImage of resized image
func resizeAnimatedGif(gif: UIImage, width: Int, height: Int) -> UIImage {
    let image = gif
    let size = gif.size
    let targetSize = CGSize(width: width, height: height)
    let widthScaleRatio = targetSize.width / image.size.width
    let heightScaleRatio = targetSize.height / image.size.height
    var newSize: CGSize
    if widthScaleRatio > heightScaleRatio {
        newSize = CGSize(width: size.width * heightScaleRatio, height: size.height * heightScaleRatio)
    } else {
        newSize = CGSize(width: size.width * widthScaleRatio,  height: size.height * widthScaleRatio)
    }
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!

}

func createAnimateArray(for name: String) -> [UIImage] {
    var i = 1
    var images = [UIImage]()
    while let image = UIImage(named: "\(name)\(i).png") {
        images.append(image)
        i += 1
    }
    i -= 1
    while let image = UIImage(named: "\(name)\(i).png") {
        images.append(image)
        i -= 1
    }
    return images
}
    
/// Custom Rounded Corner Shape which can be used as a background
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    /// Required method inherited from Shape that defines the return of the `RoundedCorner`
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
extension View {
    
    /// Custom Corner Radius styling
    ///
    /// - Parameters:
    ///     - radius:  Radius of the corner
    ///     - corners: List of corners to be rounded
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
