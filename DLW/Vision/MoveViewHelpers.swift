//
//  MoveViewHelpers.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import SwiftUI

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

func vasScaleImage() -> some View {
    let percentageCompleted : Float = Float(Move.finishedReps / Move.totalReps)
    let category : Int = percentageCompleted > 0.8 ? 1 : percentageCompleted > 0.6 ? 2 : percentageCompleted > 0.4 ? 3 : percentageCompleted > 0.2 ? 4 : 5
    var feedback : String = ""
    var flag: Bool = false
    switch(category) {
    case 1:
        feedback = "Excellent!"
        flag = true
    case 2:
        feedback = "Very good!"
        flag = true
    case 3:
        feedback = "Try a bit more!"
    case 4:
        feedback = "Try harder next time!"
    case 5:
        feedback = "Try harder next time!"
    default:
        feedback = ""
    }
    
    let body: some View = VStack {
        Text(feedback)
            .font(.system(size: 18))
            .fontWeight(.semibold)
            .padding(.horizontal)
            .foregroundColor(flag == true ? .green : .red)
    }
        .padding(.horizontal)
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
    return body
}

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
                    Text( "00:0" + String(Int(move.getShared().transitionTimer)))
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
    
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
