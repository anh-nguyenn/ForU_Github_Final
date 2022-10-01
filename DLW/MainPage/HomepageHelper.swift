//
//  HomepageHelper.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import AVFoundation

func registerForPushNotifications() {
  UNUserNotificationCenter.current()
    .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      print("Permission granted: \(granted)")
    }
}

func getWindowHeight() -> CGFloat {
    if #available(iOS 13.0, *) {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let topPadding = window?.safeAreaInsets.top
        let bottomPadding = window?.safeAreaInsets.bottom
        let height = window?.viewHeight
        return height! - topPadding! - bottomPadding!
    }
}

func getWindowWidth() -> CGFloat {
    if #available(iOS 13.0, *) {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let leftPadding = window?.safeAreaInsets.left
        let rightPadding = window?.safeAreaInsets.right
        let width = window!.viewWidth - leftPadding! - rightPadding!
        return width
    }
}


func getStatusBarHeight() -> CGFloat {
    if #available(iOS 13.0, *) {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let topPadding = window?.safeAreaInsets.top
        return topPadding!
    }

}

struct GifView : UIViewRepresentable {
    var image: UIImage
    init(image: UIImage) {
        self.image = image
    }
    
    func makeUIView(context: Context) -> some UIView {
        UIImageView(image: self.image)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

struct DraggableMoveView: View {
    
    let boxSize: CGFloat = 80
    let indexSize: CGFloat = 20
    let bodySize: CGFloat = 60
    var data: DraggableMove
    
    @Binding var draggableMoves : [DraggableMove]
    
    var body: some View {
        ZStack {
            content
            indexCircle
        }
        .frame(width: boxSize, height: boxSize)
    }
    
    var indexCircle: some View {
        Text(String(draggableMoves.firstIndex(where: { d in
            d.id == data.id
        })?.advanced(by: 1) ?? -1))
        .font(.body)
        .frame(width: indexSize, height: indexSize)
        .background(Circle().fill(Color.red))
        .frame(width: boxSize, height: boxSize, alignment: .topTrailing)
        .foregroundColor(.white)
    }
    
    var content: some View {
        GifView(image: data.move.smallImage)
            .frame(width: bodySize, height: bodySize)
            .cornerRadius(5)
    }
}

struct DropOutsideDelegate: DropDelegate {
    @Binding var current: DraggableMove?
    @Binding var changedView: Bool
        
    func dropEntered(info: DropInfo) {

        changedView = true
    }
    func performDrop(info: DropInfo) -> Bool {

        changedView = false
        current = nil
        return true
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: DraggableMove
    @Binding var listData: [DraggableMove]
    @Binding var current: DraggableMove?
    @Binding var changedView: Bool
    
    func dropEntered(info: DropInfo) {
        
        if current == nil { current = item }
        
        changedView = true
        
        if item != current {
            let from = listData.firstIndex(of: current!)!
            let to = listData.firstIndex(of: item)!
            if listData[to].id != current!.id {
                listData.move(fromOffsets: IndexSet(integer: from),
                    toOffset: to > from ? to + 1 : to)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        changedView = false
        self.current = nil
        return true
    }
}
