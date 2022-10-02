//
//  DLWApp.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import SwiftUI

@main
struct DLWApp: App {
    @StateObject var authentication = Authentication()
    var body: some Scene {
        WindowGroup {
            if authentication.isValidated {
                HomepageView()
                    .environmentObject(authentication)
            } else {
                SignInView()
                    .environmentObject(authentication)
            }
        }
    }
}
