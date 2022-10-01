//
//  HomepageModel.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import SwiftUI

class HomepageModel: ObservableObject {
  @Published var data: [DraggableMove] = []
    
    let rows = [
        GridItem(.flexible(minimum: 60, maximum: 60))
    ]

}

///  An Identifiable Wrapper for a Move
struct DraggableMove: Identifiable, Equatable {
    private static var idGen: Int = 0
    let id: Int
    let move: Move
    
    static func getNewId() -> Int {
        idGen += 1
        return idGen
    }
}

